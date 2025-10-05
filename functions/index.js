// ====================================================================
// IMPORTACIONES
// ====================================================================
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const Airtable = require("airtable");

admin.initializeApp();

// ====================================================================
// DEFINICIÓN DE SECRETOS
// ====================================================================
const airtableKey = defineSecret("AIRTABLE_KEY");
// ✅ CAMBIO: Definimos un secreto para CADA base de datos.
const airtableBaseIdDc3 = defineSecret("AIRTABLE_BASE_ID_DC3");
const airtableBaseIdBolsa = defineSecret("AIRTABLE_BASE_ID_BOLSA");


// ====================================================================
// FUNCIÓN 1: Subir metadatos de un DC-3 a Airtable
// ====================================================================
// ✅ CAMBIO: Le decimos a esta función que necesita el secreto específico de DC3.
exports.uploadDc3ToAirtable = onCall({secrets: [airtableKey, airtableBaseIdDc3]}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "El usuario no está autenticado.");
  }
  const userId = request.auth.uid;
  const { workerName, courseName, executionDate, fileUrl, fileName } = request.data;
  if (!workerName || !courseName || !executionDate || !fileUrl) {
    throw new HttpsError("invalid-argument", "Faltan datos para crear el registro.");
  }

  try {
    // ✅ CAMBIO: Usamos el valor del secreto de DC3.
    const base = new Airtable({apiKey: airtableKey.value()}).base(airtableBaseIdDc3.value());
    await base("DC3_Subidos").create([
      {"fields": { "UserId": userId, "Nombre del Trabajador": workerName, "Nombre del Curso": courseName, "Periodo de Ejecución": executionDate, "Archivo DC-3": [{ "url": fileUrl, "filename": fileName || "documento.pdf" }] }},
    ]);
    return { success: true, message: "Registro creado en Airtable." };
  } catch (error) {
    console.error("Error al crear registro en Airtable:", error);
    throw new HttpsError("internal", "Error al guardar los datos en Airtable.", error.message);
  }
});


// ====================================================================
// FUNCIÓN 2: Extraer datos de un DC-3 (Placeholder)
// ====================================================================
exports.extractDc3Data = onCall(async (request) => {
    console.log("extractDc3Data fue llamada con:", request.data);
    return { status: "Función no implementada aún." };
});


// ====================================================================
// FUNCIÓN 3: Obtener los registros de DC-3 de un usuario
// ====================================================================
const formatAirtableRecord = (record, type) => ({
  id: record.id,
  workerName: record.get("Nombre del Trabajador") || "N/A",
  courseName: record.get("Nombre del Curso") || "N/A",
  executionDate: record.get("Periodo de Ejecución"),
  fileUrl: record.get("Archivo DC-3")?.[0]?.url,
  recordType: type,
});

// ✅ CAMBIO: Le decimos a esta función que necesita el secreto específico de DC3.
exports.getDc3RecordsByUser = onCall({secrets: [airtableKey, airtableBaseIdDc3]}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "El usuario no está autenticado.");
  }
  const userId = request.auth.uid;
  const recordType = request.data.type || 'all';

  // ✅ CAMBIO: Usamos el valor del secreto de DC3.
  const base = new Airtable({apiKey: airtableKey.value()}).base(airtableBaseIdDc3.value());
  const filterFormula = `{UserId} = '${userId}'`;
  const fields = ["Nombre del Trabajador", "Nombre del Curso", "Periodo de Ejecución", "Archivo DC-3", "UserId"];
  const queryOptions = { filterByFormula: filterFormula, fields: fields };

  try {
    let records = [];
    if (recordType === 'Subido') {
      const fetchedRecords = await base("DC3_Subidos").select(queryOptions).all();
      records = fetchedRecords.map((rec) => formatAirtableRecord(rec, 'Subido'));
    } else if (recordType === 'Generado') {
      const fetchedRecords = await base("DC3_Generados").select(queryOptions).all();
      records = fetchedRecords.map((rec) => formatAirtableRecord(rec, 'Generado'));
    } else {
      const [recordsSubidos, recordsGenerados] = await Promise.all([
        base("DC3_Subidos").select(queryOptions).all(),
        base("DC3_Generados").select(queryOptions).all(),
      ]);
      const formattedSubidos = recordsSubidos.map((rec) => formatAirtableRecord(rec, 'Subido'));
      const formattedGenerados = recordsGenerados.map((rec) => formatAirtableRecord(rec, 'Generado'));
      records = [...formattedSubidos, ...formattedGenerados];
    }

    records.sort((a, b) => {
        const dateA = a.executionDate ? new Date(a.executionDate) : new Date(0);
        const dateB = b.executionDate ? new Date(b.executionDate) : new Date(0);
        return dateB - dateA;
    });

    return { records: records };
  } catch (error) {
    console.error(`Error al obtener registros de Airtable para el tipo '${recordType}':`, error);
    throw new HttpsError("internal", "No se pudieron obtener los registros.");
  }
});

// ====================================================================
// FUNCIÓN 4: Eliminar un registro de DC-3 de Airtable
// ====================================================================
// ✅ CAMBIO: Le decimos a esta función que necesita el secreto específico de DC3.
exports.deleteDc3Record = onCall({secrets: [airtableKey, airtableBaseIdDc3]}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "El usuario no está autenticado.");
  }
  const { recordId } = request.data;
  if (!recordId) {
    throw new HttpsError("invalid-argument", "Se requiere el ID del registro para eliminarlo.");
  }

  // ✅ CAMBIO: Usamos el valor del secreto de DC3.
  const base = new Airtable({apiKey: airtableKey.value()}).base(airtableBaseIdDc3.value());
  let deleted = false;
  let lastError = null;

  try {
    await base("DC3_Subidos").destroy([recordId]);
    console.log(`Registro ${recordId} eliminado de DC3_Subidos.`);
    deleted = true;
  } catch (error) {
    console.log(`Registro ${recordId} no encontrado en DC3_Subidos. Intentando en DC3_Generados...`);
    lastError = error;
  }

  if (!deleted) {
    try {
      await base("DC3_Generados").destroy([recordId]);
      console.log(`Registro ${recordId} eliminado de DC3_Generados.`);
      deleted = true;
    } catch (error) {
      console.error(`Error al eliminar ${recordId} de DC3_Generados:`, error);
      lastError = error;
    }
  }

  if (deleted) {
    return { success: true, message: "Registro eliminado correctamente." };
  } else {
    console.error(`No se pudo eliminar el registro ${recordId} de ninguna tabla.`, lastError);
    throw new HttpsError("not-found", "El registro no se encontró o no se pudo eliminar.", lastError?.message);
  }
});


// ====================================================================
// FUNCIÓN 5: ENVIAR RESUMEN DIARIO DE POSTULACIONES (BOLSA DE TRABAJO)
// ====================================================================
// ✅ CAMBIO: Le decimos a esta función que necesita el secreto específico de la Bolsa de Trabajo.
exports.enviarResumenDePostulaciones = onSchedule({
  schedule: "every day 09:00",
  timeZone: "America/Mexico_City",
  secrets: [airtableKey, airtableBaseIdBolsa],
}, async (event) => {
  console.log("Iniciando revisión diaria de nuevas postulaciones.");

  try {
    // ✅ CAMBIO: Usamos el valor del secreto de la Bolsa de Trabajo.
    const base = new Airtable({apiKey: airtableKey.value()}).base(airtableBaseIdBolsa.value());

    const records = await base("Aplicaciones").select({
      filterByFormula: "{Notificacion_Enviada} = 0",
    }).all();

    if (records.length === 0) {
      console.log("No hay nuevas postulaciones para notificar. Terminando.");
      return null;
    }
    console.log(`Se encontraron ${records.length} postulaciones nuevas.`);

    const postulacionesPorReclutador = records.reduce((acc, record) => {
      const reclutadorId = record.get("UserID_Reclutador_Vacante")?.[0];
      if (reclutadorId) {
        if (!acc[reclutadorId]) { acc[reclutadorId] = []; }
        acc[reclutadorId].push(record);
      }
      return acc;
    }, {});

    const fcm = admin.messaging();
    const firestore = admin.firestore();

    for (const reclutadorId in postulacionesPorReclutador) {
      const numPostulaciones = postulacionesPorReclutador[reclutadorId].length;
      const titulo = `Tienes ${numPostulaciones} nueva(s) postulación(es)`;
      const cuerpo = "Revisa los nuevos candidatos que aplicaron a tus vacantes.";

      const tokenDoc = await firestore.collection("fcm_tokens").doc(reclutadorId).get();
      if (tokenDoc.exists) {
        const fcmToken = tokenDoc.data().token;
        const message = {
          notification: { title: titulo, body: cuerpo },
          token: fcmToken,
        };
        await fcm.send(message);
        console.log(`Notificación de resumen enviada a ${reclutadorId}.`);
      }
    }

    const updates = records.map((record) => ({
      id: record.id,
      fields: { "Notificacion_Enviada": true },
    }));

    for (let i = 0; i < updates.length; i += 10) {
      const batch = updates.slice(i, i + 10);
      await base("Aplicaciones").update(batch);
    }

    console.log(`${records.length} postulaciones marcadas como notificadas.`);
    return null;

  } catch (error) {
    console.error("Error ejecutando la función programada:", error);
    return null;
  }
});