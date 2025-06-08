import json
from typing import Any, Dict
import functions_framework
from google.cloud import firestore
import vertexai
from vertexai.preview.generative_models import (GenerativeModel,Part)

ID_PROJECT        = "ia-recipe-project"
IA_SERVER   = "us-central1"
MODEL_IA          = "gemini-2.5-flash-preview-05-20"
MSG_IA = """
Devuélveme ÚNICAMENTE un JSON válido sin texto adicional con estas claves exactas:
nombre_receta (string),
personas (entero),
tiempo_total (entero, minutos),
imagen (url https),
ingredientes (array string),
pasos_con_tiempo (array string),
alergenos (array string, escogidos únicamente de esta lista exacta: ["Gluten", "Crustacis", "Ous", "Peix", "Cacauets", "Soja", "Llet", "Fruits de closca", "Api", "Mostassa", "Grans de sèsam", "Diòxid de sofre i sulfits", "Tramussos", "Mol·luscs"]).
No añadas ningún comentario. Dame el resultado en catalán
""".strip()

# Inicialitzacions
db = firestore.Client()
vertexai.init(project=ID_PROJECT, location=IA_SERVER)
GenerativeModel = GenerativeModel(MODEL_IA)

# DEBUG
def show_error(msg, code):
    return (json.dumps({"error": msg}), code, {"Content-Type": "application/json"})

# Entry point de la funció
def genRecipe(request):
    # Obtenció de la petició de l'usuari i obtenció de la ruta
    # en el bucket d'imatges escanejades
    payload = request.get_json(silent=True) or {}
    gcs_uri = payload.get("gcsUri")

    # Comprovem que el missatge tingui una ruta vàlida al bucket d'imatges
    if not (isinstance(gcs_uri, str) and gcs_uri.startswith("gs://")):
        return show_error("Error en el missatge, no arriba una ruta del bucket", -1)

    try:
        # Al treballar amb strings i imatges formem el missatge complet a partir de les
        # dues parts.
        msg_complet = [Part.from_uri(gcs_uri, mime_type="image/jpeg"),
            Part.from_text(MSG_IA)]
        # Enviem la petició al Gemini i demanem resposta en format json
        response = model.generate_content(
            msg_complet,
            generation_config={"response_mime_type": "application/json"},
        )
        raw = response.text
        # Ens assegurem que el format sigui vàlid (falla a vegades :( )
        recipe = json.loads(raw)
    except Exception as exc:
        return show_error(f"Error generant recepta: {exc}", -1)

    # Completem les dades amb la imatge que ha pujat l'usuari (és la que es mostra a l'aplicació)
    # No té sentit que ho faci el Gemini
    recipe["imagen"] = f"https://storage.googleapis.com/{gcs_uri.replace('gs://', '')}"

    # Comprovem si ja tenim una recepta guardada a la base de dades amb aquest nom
    query = (db.collection("recipes").where("nombre_receta", "==", recipe["nombre_receta"])
                .limit(1).stream())
    resp = next(query, None)

    if resp:  # ja existeix --> retornem la recepta i no afegim res
        return (
            json.dumps({"id": resp.id, **resp.to_dict()}),
                200,{"Content-Type": "application/json"},)

    # Si no existeix l'afegim al Firestore
    new_recipe = db.collection("recipes").add({**recipe, "likes": 0})[1] # Em vaig deixar els likes quick fix

    # Retornem la recepta a flutter
    result = {"id": new_recipe.id, **recipe, "likes": 0}
    return (json.dumps(result), 200, {"Content-Type": "application/json"})
