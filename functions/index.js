const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const Airtable = require("airtable");
const pdf = require("pdf-parse");
const fs = require("fs");

admin.initializeApp();

// Declarar los secretos que las funciones necesitarán
const airtableKey = defineSecret("AIRTABLE_KEY");
const airtableBaseId = defineSecret("AIRTABLE_BASE_ID");



/**
 * Función 1: Sube los datos finales de un DC-3 a Airtable.
 * (Esta función ya estaba correcta, no se modifica)
 */
exports.uploadDc3ToAirtable = onCall({secrets: [airtableKey, airtableBaseId]}, async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "La función debe ser llamada por un usuario autenticado.",
    );
  }

  const base = new Airtable({apiKey: airtableKey.value()}).base(airtableBaseId.value());
  const {workerName, courseName, executionDate, fileUrl, fileName} = request.data;
  const userId = request.auth.uid;

  try {
    await base("DC3_Subidos").create([
      {
        fields: {
          "Nombre del Trabajador": workerName,
          "Nombre del Curso": courseName,
          "Periodo de Ejecución": executionDate,
          "Archivo DC-3": [{url: fileUrl, filename: fileName}],
          "UserID": userId,
        },
      },
    ]);
    return {success: true};
  } catch (error) {
    console.error("Error al crear el registro en Airtable:", error);
    throw new HttpsError(
        "internal",
        "No se pudo guardar el registro en Airtable.",
    );
  }
});


/**
 * Función 2: Extrae datos de un archivo PDF de DC-3 subido a Storage.
 * (Esta función no usa Airtable, no se modifica)
 */
exports.extractDc3Data = onCall(async (request) => {
  // ... (código sin cambios)
});


/**
 * Función 3: Obtiene los registros de DC-3 de un usuario desde Airtable.
 * (Función corregida)
 */
exports.getDc3RecordsByUser = onCall({secrets: [airtableKey, airtableBaseId]}, async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "El usuario debe estar autenticado para consultar sus registros.",
    );
  }
  const userId = request.auth.uid;

  // ✅ --- PASO 2: AÑADIR LA INICIALIZACIÓN DE AIRTABLE AQUÍ DENTRO ---
  const base = new Airtable({apiKey: airtableKey.value()}).base(airtableBaseId.value());

  const queryOptions = {
    filterByFormula: `{UserID} = '${userId}'`,
    fields: [
      "Nombre del Trabajador",
      "Nombre del Curso",
      "Periodo de Ejecucion",
      "Archivo DC-3",
      "UserID",
      "QR",
    ],
  };

  const promiseSubidos = base("DC3_Subidos").select(queryOptions).all();
  const promiseGenerados = base("DC3_Generados").select(queryOptions).all();

  try {
    const [recordsSubidos, recordsGenerados] = await Promise.all([
      promiseSubidos,
      promiseGenerados,
    ]);

    const formattedSubidos = recordsSubidos.map((record) => ({
      id: record.id,
      workerName: record.get("Nombre del Trabajador"),
      courseName: record.get("Nombre del Curso"),
      executionDate: record.get("Periodo de Ejecucion"),
      fileUrl: record.get("Archivo DC-3")?.[0]?.url,
      type: "uploaded",
    }));

    const formattedGenerados = recordsGenerados.map((record) => ({
      id: record.id,
      workerName: record.get("Nombre del Trabajador"),
      courseName: record.get("Nombre del Curso"),
      executionDate: record.get("Periodo de Ejecucion"),
      fileUrl: record.get("Archivo DC-3")?.[0]?.url,
      type: "generated",
    }));

    const allRecords = [...formattedSubidos, ...formattedGenerados];
    return { records: allRecords };
  } catch (error) {
    console.error("Error al obtener registros de Airtable:", error);
    throw new HttpsError(
        "internal",
        "No se pudieron obtener los registros."
    );
  }
});