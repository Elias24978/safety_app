const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const Airtable = require("airtable");

admin.initializeApp();

const airtableKey = defineSecret("AIRTABLE_KEY");
const airtableBaseId = defineSecret("AIRTABLE_BASE_ID");

// ====================================================================
// FUNCIÓN 1: Subir metadatos de un DC-3 a Airtable
// ====================================================================
exports.uploadDc3ToAirtable = onCall({secrets: [airtableKey, airtableBaseId]}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "El usuario no está autenticado.");
  }
  const userId = request.auth.uid;

  const { workerName, courseName, executionDate, fileUrl, fileName } = request.data;
  if (!workerName || !courseName || !executionDate || !fileUrl) {
    throw new HttpsError("invalid-argument", "Faltan datos para crear el registro.");
  }

  try {
    const base = new Airtable({apiKey: airtableKey.value()}).base(airtableBaseId.value());
    await base("DC3_Subidos").create([
      {
        "fields": {
          // ✅ CAMBIO: Se ajustó a "UserId" con 'd' minúscula.
          "UserId": userId,
          "Nombre del Trabajador": workerName,
          "Nombre del Curso": courseName,
          "Periodo de Ejecución": executionDate,
          "Archivo DC-3": [{ "url": fileUrl, "filename": fileName || "documento.pdf" }],
          // ✅ CAMBIO: Se eliminó la línea "Tipo": "Subido".
        },
      },
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

exports.getDc3RecordsByUser = onCall({secrets: [airtableKey, airtableBaseId]}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "El usuario no está autenticado.");
  }
  const userId = request.auth.uid;
  const recordType = request.data.type || 'all';

  const base = new Airtable({apiKey: airtableKey.value()}).base(airtableBaseId.value());
  // ✅ CAMBIO: Se ajustó el filtro para usar "UserId" con 'd' minúscula.
  const filterFormula = `{UserId} = '${userId}'`;
  // ✅ CAMBIO: Se agregó "UserId" a la lista de campos para asegurar que el filtro funcione correctamente.
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
exports.deleteDc3Record = onCall({secrets: [airtableKey, airtableBaseId]}, async (request) => {
  // 1. Verificar autenticación del usuario
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "El usuario no está autenticado.");
  }

  // 2. Obtener el ID del registro desde la app
  const { recordId } = request.data;
  if (!recordId) {
    throw new HttpsError("invalid-argument", "Se requiere el ID del registro para eliminarlo.");
  }

  const base = new Airtable({apiKey: airtableKey.value()}).base(airtableBaseId.value());
  let deleted = false;
  let lastError = null;

  // 3. Intentar eliminar de la tabla 'DC3_Subidos'
  try {
    await base("DC3_Subidos").destroy([recordId]);
    console.log(`Registro ${recordId} eliminado de DC3_Subidos.`);
    deleted = true;
  } catch (error) {
    // Si no se encuentra aquí, es normal. Guardamos el error por si acaso.
    console.log(`Registro ${recordId} no encontrado en DC3_Subidos. Intentando en DC3_Generados...`);
    lastError = error;
  }

  // 4. Si no se eliminó de la primera tabla, intentar en 'DC3_Generados'
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

  // 5. Devolver el resultado
  if (deleted) {
    return { success: true, message: "Registro eliminado correctamente." };
  } else {
    // Si no se encontró en ninguna tabla o hubo otro error
    console.error(`No se pudo eliminar el registro ${recordId} de ninguna tabla.`, lastError);
    throw new HttpsError("not-found", "El registro no se encontró o no se pudo eliminar.", lastError?.message);
  }
});