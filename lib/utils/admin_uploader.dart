import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUploader {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Sube el temario de un curso específico usando su ID de documento.
  Future<void> uploadCursoTemario(String docId, String jsonString) async {
    try {
      // 1. Decodificar el JSON a una lista de objetos Dart
      final List<dynamic> temarioList = json.decode(jsonString);

      // 2. Referencia al documento en Firestore
      final docRef = _db.collection('cursos').doc(docId);

      // 3. Subir/Actualizar el documento
      await docRef.set({
        'temario': temarioList,
        'ultima_actualizacion': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅ ¡Curso subido exitosamente a Firestore! (ID: $docId)");
    } catch (e) {
      print("❌ Error subiendo curso: $e");
      rethrow;
    }
  }

  /// Método para subir el Curso NOM-009.
  /// [customId] es opcional. Si no se envía, usa el ID por defecto.
  /// Esto corrige el error "Too many positional arguments".
  Future<void> uploadTrabajoEnAlturasDemo([String? customId]) async {
    // ID proporcionado por el usuario (si viene desde el menú) o el valor por defecto
    final String targetId = customId ?? 'recntDHkfShryxxfZ';

    // NOTA PARA EL USUARIO:
    // - Para videos de YouTube: Usa configuración "No listado".
    // - Para PDFs de Drive: Usa "Cualquiera con el enlace" (Lector).

    const String jsonContent = '''
[
  {
    "modulo_titulo": "Bienvenida e Introducción",
    "descripcion": "Inicio del curso y familiarización con la plataforma.",
    "lecciones": [
      {
        "titulo": "Bienvenida y Metodología",
        "tipo": "video",
        "url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        "duracion": 15,
        "descripcion": "Presentación de objetivos, alcance de la NOM-009 y navegación por el sistema.",
        "material_apoyo": []
      }
    ]
  },
  {
    "modulo_titulo": "Fundamentos y Gestión de Riesgos",
    "descripcion": "Marco legal, definiciones críticas y análisis previo al trabajo.",
    "lecciones": [
      {
        "titulo": "Introducción y Marco Legal",
        "tipo": "video",
        "url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        "duracion": 40,
        "descripcion": "Objetivo, campo de aplicación y marco jurídico (LFT, RFS). Definiciones críticas.",
        "material_apoyo": []
      },
      {
        "titulo": "Responsabilidades en el Centro de Trabajo",
        "tipo": "pdf",
        "url": "https://www.stps.gob.mx/bp/secciones/dgsst/normatividad/normas/Nom-009.pdf",
        "duracion": 30,
        "descripcion": "Lectura obligatoria: Obligaciones del patrón y del trabajador.",
        "material_apoyo": []
      },
      {
        "titulo": "Análisis de Seguridad (AST) y Permisos",
        "tipo": "video",
        "url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        "duracion": 50,
        "descripcion": "Identificación de riesgos ambientales/estructurales y llenado de autorización por escrito.",
        "material_apoyo": []
      }
    ]
  },
  {
    "modulo_titulo": "Sistemas Personales de Protección",
    "descripcion": "Clasificación, componentes y mantenimiento del EPP.",
    "lecciones": [
      {
        "titulo": "Clasificación de Sistemas Personales",
        "tipo": "video",
        "url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
        "duracion": 40,
        "descripcion": "Diferencias entre restricción, posicionamiento y detención de caídas.",
        "material_apoyo": []
      },
      {
        "titulo": "Componentes y Selección de Equipo",
        "tipo": "video",
        "url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        "duracion": 40,
        "descripcion": "Arneses, líneas de vida, amortiguadores y puntos de anclaje.",
        "material_apoyo": []
      },
      {
        "titulo": "Inspección y Mantenimiento de EPP",
        "tipo": "video",
        "url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        "duracion": 40,
        "descripcion": "Protocolo de revisión pre-uso y criterios de retiro inmediato (checklist).",
        "material_apoyo": [
          {
            "titulo": "Checklist de Inspección EPP.pdf",
            "url": "https://firebasestorage.googleapis.com/v0/b/tu-app/o/checklist_epp.pdf"
          }
        ]
      }
    ]
  },
  {
    "modulo_titulo": "Equipos Auxiliares y Accesos",
    "descripcion": "Andamios, plataformas, escaleras y redes.",
    "lecciones": [
      {
        "titulo": "Andamios: Torre y Suspendidos",
        "tipo": "video",
        "url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        "duracion": 45,
        "descripcion": "Armado seguro, nivelación, contrapesos y líneas de vida independientes.",
        "material_apoyo": []
      },
      {
        "titulo": "Plataformas de Elevación y Escaleras",
        "tipo": "video",
        "url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
        "duracion": 45,
        "descripcion": "Uso de PEMP y regla de los 3 puntos en escaleras de mano.",
        "material_apoyo": []
      },
      {
        "titulo": "Redes de Seguridad",
        "tipo": "pdf",
        "url": "https://www.stps.gob.mx/bp/secciones/dgsst/normatividad/normas/Nom-009.pdf",
        "duracion": 30,
        "descripcion": "Requerimientos técnicos de instalación y distancias de amortiguamiento.",
        "material_apoyo": []
      }
    ]
  },
  {
    "modulo_titulo": "Salud, Emergencias y Cumplimiento",
    "descripcion": "Vigilancia médica, rescate y cierre administrativo.",
    "lecciones": [
      {
        "titulo": "Condiciones de Salud y Vigilancia",
        "tipo": "pdf",
        "url": "https://www.stps.gob.mx/bp/secciones/dgsst/normatividad/normas/Nom-009.pdf",
        "duracion": 30,
        "descripcion": "Factores limitantes (vértigo, etc.) y exámenes médicos obligatorios.",
        "material_apoyo": []
      },
      {
        "titulo": "Plan de Atención a Emergencias",
        "tipo": "video",
        "url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        "duracion": 50,
        "descripcion": "Protocolo de rescate, trauma por suspensión y botiquín.",
        "material_apoyo": []
      },
      {
        "titulo": "Evaluación de Conformidad y Cierre",
        "tipo": "video",
        "url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        "duracion": 40,
        "descripcion": "Inspecciones STPS y trámite de Constancia DC-3.",
        "material_apoyo": []
      }
    ]
  },
  {
    "modulo_titulo": "Examen Final y Certificación",
    "descripcion": "Evaluación final para la obtención de constancia DC-3.",
    "lecciones": [
      {
        "titulo": "Examen Final NOM-009-STPS-2011",
        "tipo": "examen",
        "url": "",
        "duracion": 60,
        "descripcion": "Cuestionario de evaluación de conocimientos.",
        "material_apoyo": [],
        "preguntas": [
          {
            "pregunta": "¿Qué documento es indispensable tramitar ANTES de iniciar cualquier trabajo en altura?",
            "opciones": [
              "Recibo de nómina",
              "Permiso de trabajo con análisis de riesgos",
              "Bitácora de asistencia",
              "Factura del equipo"
            ],
            "correcta": 1
          },
          {
            "pregunta": "En un sistema de interrupción de caídas, ¿cuál es la función del absorbedor de energía?",
            "opciones": [
              "Hacer la línea más larga",
              "Disipar la energía cinética para reducir el impacto en el cuerpo",
              "Servir como cuerda de rescate",
              "Evitar que el trabajador se mueva"
            ],
            "correcta": 1
          },
          {
            "pregunta": "¿Cuál es la vigencia máxima de los exámenes médicos para trabajadores de altura según la NOM-009?",
            "opciones": [
              "Cada 6 meses",
              "Cada año (Anual)",
              "Cada 2 años",
              "Solo al ingreso"
            ],
            "correcta": 1
          },
          {
            "pregunta": "¿Qué organismo acreditado puede emitir un dictamen oficial de cumplimiento de la norma en el centro de trabajo?",
            "opciones": [
              "El sindicato",
              "Una Unidad de Verificación (UV)",
              "El supervisor de obra",
              "Protección Civil Municipal"
            ],
            "correcta": 1
          },
          {
            "pregunta": "¿Cuál es la regla de seguridad básica al utilizar escaleras de mano para ascender o descender?",
            "opciones": [
              "Subir lo más rápido posible",
              "Llevar herramientas en ambas manos",
              "Mantener siempre 3 puntos de contacto (dos manos y un pie, o dos pies y una mano)",
              "Saltar los últimos escalones"
            ],
            "correcta": 2
          },
          {
            "pregunta": "¿Qué condición médica crítica puede ocurrir si una persona queda suspendida del arnés por tiempo prolongado?",
            "opciones": [
              "Trauma por suspensión (Síndrome del arnés)",
              "Deshidratación inmediata",
              "Hipotermia",
              "Cambre muscular simple"
            ],
            "correcta": 0
          }
        ]
      }
    ]
  }
]
''';

    await uploadCursoTemario(targetId, jsonContent);
  }
}