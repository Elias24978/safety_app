const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const Airtable = require("airtable");

admin.initializeApp();

// Define los secretos necesarios para las funciones.
const airtableKey = defineSecret("AIRTABLE_KEY");
const airtableBaseId = defineSecret("AIRTABLE_BASE_ID");

// --- TUS OTRAS FUNCIONES (uploadDc3ToAirtable, extractDc3Data) PERMANECEN IGUAL ---
exports.uploadDc3ToAirtable = onCall({secrets: [airtableKey, airtableBaseId]}, async (request) => {
    // ... tu código existente
});

exports.extractDc3Data = onCall(async (request) => {
    // ... tu código existente
});


/**
 * Función auxiliar para dar formato a los registros de Airtable y evitar repetir código.
 * @param {object} record - El registro original de Airtable.
 * @param {string} type - El tipo de registro ('uploaded' o 'generated').
 * @returns {object} El registro formateado para la app.
 */
const formatAirtableRecord = (record, type) => ({
  id: record.id,
  workerName: record.get("Nombre del Trabajador") || "N/A",
  courseName: record.get("Nombre del Curso") || "N/A",
  executionDate: record.get("Periodo de Ejecución"),
  fileUrl: record.get("Archivo DC-3")?.[0]?.url,
  type: type,
});


/**
 * ✅ FUNCIÓN ACTUALIZADA Y MÁS FLEXIBLE
 * Obtiene registros de DC-3 según un tipo específico ('uploaded', 'generated', o 'all').
 */
exports.getDc3RecordsByUser = onCall({secrets: [airtableKey, airtableBaseId]}, async (request) => {
  // 1. Verificar que el usuario esté autenticado.
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "El usuario no está autenticado.");
  }
  const userId = request.auth.uid;

  // ✅ 2. Obtener el tipo de registro solicitado desde la app. Si no viene, trae todos.
  const recordType = request.data.type || 'all';

  const base = new Airtable({apiKey: airtableKey.value()}).base(airtableBaseId.value());
  const filterFormula = `{UserID} = '${userId}'`;
  const fields = ["Nombre del Trabajador", "Nombre del Curso", "Periodo de Ejecución", "Archivo DC-3"];
  const queryOptions = { filterByFormula: filterFormula, fields: fields };

  try {
    let records = [];

    // ✅ 3. Lógica para decidir qué tabla(s) consultar según el parámetro 'recordType'.
    if (recordType === 'uploaded') {
      const fetchedRecords = await base("DC3_Subidos").select(queryOptions).all();
      records = fetchedRecords.map(rec => formatAirtableRecord(rec, 'uploaded'));
    } else if (recordType === 'generated') {
      const fetchedRecords = await base("DC3_Generados").select(queryOptions).all();
      records = fetchedRecords.map(rec => formatAirtableRecord(rec, 'generated'));
    } else { // Si es 'all' o cualquier otro valor, combina ambas tablas.
      const [recordsSubidos, recordsGenerados] = await Promise.all([
        base("DC3_Subidos").select(queryOptions).all(),
        base("DC3_Generados").select(queryOptions).all(),
      ]);
      const formattedSubidos = recordsSubidos.map(rec => formatAirtableRecord(rec, 'uploaded'));
      const formattedGenerados = recordsGenerados.map(rec => formatAirtableRecord(rec, 'generated'));
      records = [...formattedSubidos, ...formattedGenerados];
    }

    // 4. Ordenar los resultados por fecha de ejecución.
    records.sort((a, b) => {
        const dateA = a.executionDate ? new Date(a.executionDate) : new Date(0);
        const dateB = b.executionDate ? new Date(b.executionDate) : new Date(0);
        return dateB - dateA; // Ordena de más reciente a más antiguo
    });

    return { records: records };

  } catch (error) {
    // Loguea el error detallado en la consola de Google Cloud para facilitar la depuración.
    console.error(`Error al obtener registros de Airtable para el tipo '${recordType}':`, error);
    throw new HttpsError("internal", "No se pudieron obtener los registros.");
  }
});