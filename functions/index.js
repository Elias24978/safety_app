const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const Airtable = require("airtable");

admin.initializeApp();

// ====================================================================
// CREDENCIALES FIJAS (HARDCODED)
// ====================================================================
const API_KEY_AIRTABLE = "pat3YqMlmuiIQOhgi.1b3145f5af57d8d4926e94226e26d1dcf5859eab7765e733d5a2f8777eca503b";
const BASE_ID_DC3_PROD = "apphA62JHN1kyQB57";
const BASE_ID_BOLSA_PROD = "apptx3lCUup3nTVw3";

// CREDENCIALES DEL DC-3 (Webhook)
const WEBHOOK_DC3_URL = "https://script.google.com/macros/s/AKfycbxbOrb6nVABpd935qCdTfILIK5guuioa7DGTI11Ze5gehz-euPj96ZN4_n6pEIzhTf_/exec";
const WEBHOOK_API_TOKEN = "SAFETY_APP_SECURE_TOKEN_2024";

// ====================================================================
// FUNCIÓN 1: Subir metadatos de un DC-3 a Airtable
// ====================================================================
exports.uploadDc3ToAirtable = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "El usuario no está autenticado.");
  }
  const userId = request.auth.uid;
  const { workerName, courseName, executionDate, fileUrl, fileName } = request.data;

  if (!workerName || !courseName || !executionDate || !fileUrl) {
    throw new HttpsError("invalid-argument", "Faltan datos para crear el registro.");
  }

  try {
    const base = new Airtable({apiKey: API_KEY_AIRTABLE}).base(BASE_ID_DC3_PROD);
    await base("DC3_Subidos").create([
      {"fields": {
        "UserId": userId,
        "Nombre del Trabajador": workerName,
        "Nombre del Curso": courseName,
        "Periodo de Ejecución": executionDate,
        "Archivo DC-3": [{ "url": fileUrl, "filename": fileName || "documento.pdf" }]
      }},
    ]);
    return { success: true, message: "Registro creado en Airtable." };
  } catch (error) {
    console.error("Error al crear registro en Airtable:", error);
    throw new HttpsError("internal", `Airtable rechazó la subida: ${error.message}`);
  }
});

// ====================================================================
// FUNCIÓN 2: Extraer datos de un DC-3 (Placeholder)
// ====================================================================
exports.extractDc3Data = onCall(async (request) => {
    return { status: "Función no implementada aún." };
});

// ====================================================================
// FUNCIÓN 3: Obtener los registros de DC-3 de un usuario
// ====================================================================
const formatAirtableRecord = (record, type) => ({
  id: record.id,
  workerName: record.get("Nombre del Trabajador") || "N/A",
  courseName: record.get("Nombre del Curso") || "N/A",
  executionDate: record.get("Periodo de Ejecución") || record.get("Fecha de Emision") || "N/A",
  fileUrl: record.get("Archivo DC-3") ? record.get("Archivo DC-3")[0]?.url : null,
  recordType: type,
});

exports.getDc3RecordsByUser = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "El usuario no está autenticado.");

  const userId = request.auth.uid;

  const base = new Airtable({apiKey: API_KEY_AIRTABLE}).base(BASE_ID_DC3_PROD);
  const queryOptions = { filterByFormula: `{UserId} = '${userId}'` };

  try {
    // 🚨 BUG BOUNTY PATCH: Por solicitud, ahora esta función SOLO lee de la tabla DC3_Subidos
    // Ignorando completamente la tabla DC3_Generados_SafetyMex para la pantalla "Mis Constancias"
    const fetchedRecords = await base("DC3_Subidos").select(queryOptions).all();
    let records = fetchedRecords.map((rec) => formatAirtableRecord(rec, 'Subido'));

    // Ordenar los registros por fecha de más reciente a más antiguo
    records.sort((a, b) => {
        const dateA = a.executionDate !== "N/A" ? new Date(a.executionDate) : new Date(0);
        const dateB = b.executionDate !== "N/A" ? new Date(b.executionDate) : new Date(0);
        return dateB - dateA;
    });

    return { records: records };
  } catch (error) {
    console.error(`Error al obtener registros:`, error);
    throw new HttpsError("internal", `Error de lectura en Airtable: ${error.message}`);
  }
});

// ====================================================================
// FUNCIÓN 4: Eliminar un registro de DC-3 de Airtable
// ====================================================================
exports.deleteDc3Record = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "No autenticado.");
  const { recordId } = request.data;
  const base = new Airtable({apiKey: API_KEY_AIRTABLE}).base(BASE_ID_DC3_PROD);
  let deleted = false;
  let lastError = null;

  try {
    await base("DC3_Subidos").destroy([recordId]);
    deleted = true;
  } catch (error) {
    lastError = error;
  }

  if (!deleted) {
    try {
      await base("DC3_Generados_SafetyMex").destroy([recordId]);
      deleted = true;
    } catch (error) {
      lastError = error;
    }
  }

  if (deleted) return { success: true, message: "Registro eliminado." };
  throw new HttpsError("not-found", "No se pudo eliminar.", lastError?.message);
});

// ====================================================================
// FUNCIÓN 5: ENVIAR RESUMEN DIARIO DE POSTULACIONES
// ====================================================================
exports.enviarResumenDePostulaciones = onSchedule({
  schedule: "every day 09:00",
  timeZone: "America/Mexico_City"
}, async (event) => {
  console.log("Revisión diaria en proceso...");
  return null;
});

// ====================================================================
// ✅ FUNCIÓN 6: GENERAR DC-3 Y GUARDAR EN AIRTABLE
// ====================================================================
exports.generarDC3 = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Debes iniciar sesión.");

  const data = request.data;
  const uid = request.auth.uid;

  try {
    const response = await fetch(WEBHOOK_DC3_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Authorization": `Bearer ${WEBHOOK_API_TOKEN}` },
      body: JSON.stringify(data)
    });
    const result = await response.json();

    if (result.status === "success") {
      const base = new Airtable({apiKey: API_KEY_AIRTABLE}).base(BASE_ID_DC3_PROD);
      const fechaActual = new Date();
      const fechaFormateada = `${fechaActual.getDate().toString().padStart(2, '0')}/${(fechaActual.getMonth() + 1).toString().padStart(2, '0')}/${fechaActual.getFullYear()}`;

      await base("DC3_Generados_SafetyMex").create([
        {"fields": {
          "Folio": data.folio,
          "Nombre del Trabajador": data.nombre,
          "CURP": data.curp,
          "Nombre del Curso": data.curso,
          "Duracion": data.duracion,
          "Instructor": data.instructor,
          "Fecha de Emision": fechaFormateada,
          "Calificacion": 10.0,
          "UserId": uid
        }},
      ]);
      return { success: true, message: "Constancia DC-3 generada y registrada." };
    } else {
      throw new HttpsError("internal", result.message || "Fallo en Google Script.");
    }
  } catch (error) {
    throw new HttpsError("internal", `Error al generar o guardar DC3: ${error.message}`);
  }
});

// ====================================================================
// ✅ FUNCIÓN 7: VALIDAR FOLIO DE DC-3 EN AIRTABLE
// ====================================================================
exports.validarFolioDC3 = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Debes iniciar sesión.");

  const { folio } = request.data;
  if (!folio) throw new HttpsError("invalid-argument", "Se requiere un folio.");

  try {
    const base = new Airtable({apiKey: API_KEY_AIRTABLE}).base(BASE_ID_DC3_PROD);
    const queryOptions = { filterByFormula: `{Folio} = '${folio}'`, maxRecords: 1 };
    const fetchedRecords = await base("DC3_Generados_SafetyMex").select(queryOptions).firstPage();

    if (fetchedRecords.length > 0) {
      const record = fetchedRecords[0];
      return {
        encontrado: true,
        datos: {
          folio: record.get("Folio"),
          nombreTrabajador: record.get("Nombre del Trabajador") || "N/A",
          curp: record.get("CURP") || "N/A",
          nombreCurso: record.get("Nombre del Curso") || "N/A",
          duracion: record.get("Duracion") || "N/A",
          instructor: record.get("Instructor") || "N/A",
          fechaEmision: record.get("Fecha de Emision") || "N/A",
          calificacion: record.get("Calificacion") || "N/A"
        }
      };
    } else {
      return { encontrado: false, datos: null };
    }
  } catch (error) {
    throw new HttpsError("internal", `Hubo un problema al validar: ${error.message}`);
  }
});