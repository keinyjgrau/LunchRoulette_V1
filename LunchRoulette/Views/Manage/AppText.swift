//
//  AppText.swift
//  LunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-05-27.
//

import Foundation

enum AppLanguageOption: String, CaseIterable, Identifiable {
    case system
    case english
    case spanish

    var id: String { rawValue }
}

enum AppText {
    static func code(_ preference: String) -> String {
        switch preference {
        case AppLanguageOption.english.rawValue:
            return "en"
        case AppLanguageOption.spanish.rawValue:
            return "es"
        default:
            let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
            return preferred.hasPrefix("es") ? "es" : "en"
        }
    }

    static func isSpanish(_ preference: String) -> Bool {
        code(preference) == "es"
    }

    static func text(_ preference: String, en: String, es: String) -> String {
        isSpanish(preference) ? es : en
    }

    static func tabHome(_ p: String) -> String { text(p, en: "Home", es: "Inicio") }
    static func tabPick(_ p: String) -> String { text(p, en: "Pick", es: "Elegir") }
    static func tabManage(_ p: String) -> String { text(p, en: "Manage", es: "Administrar") }
    static func tabSettings(_ p: String) -> String { text(p, en: "Settings", es: "Ajustes") }

    static func homeTitle(_ p: String) -> String { text(p, en: "Lunch Roulette", es: "Ruleta de Almuerzo") }
    static func homeSubtitle(_ p: String) -> String {
        text(p,
             en: "Choose a place to eat with a fun restaurant roulette experience.",
             es: "Elige un lugar para comer con una divertida experiencia de ruleta de restaurantes.")
    }
    static func homeChooseLunch(_ p: String) -> String { text(p, en: "Choose Lunch", es: "Elegir Almuerzo") }
    static func homeRestaurants(_ p: String) -> String { text(p, en: "Restaurants", es: "Restaurantes") }
    static func homeSettings(_ p: String) -> String { text(p, en: "Settings", es: "Ajustes") }
    static func homeFooter(_ p: String) -> String {
        text(p,
             en: "Pick your restaurants, spin the wheel, and let luck decide.",
             es: "Elige tus restaurantes, gira la ruleta y deja que la suerte decida.")
    }

    static func chooseLunchTitle(_ p: String) -> String { text(p, en: "Choose Lunch", es: "Elegir Almuerzo") }
    static func restaurantSource(_ p: String) -> String { text(p, en: "Restaurant source", es: "Fuente de restaurantes") }
    static func local(_ p: String) -> String { text(p, en: "Local", es: "Local") }
    static func nearby(_ p: String) -> String { text(p, en: "Nearby", es: "Cercanos") }
    static func refresh(_ p: String) -> String { text(p, en: "Refresh", es: "Actualizar") }
    static func search(_ p: String) -> String { text(p, en: "Search", es: "Buscar") }

    static func filters(_ p: String) -> String { text(p, en: "Filters", es: "Filtros") }
    static func distance(_ p: String) -> String { text(p, en: "Distance", es: "Distancia") }
    static func category(_ p: String) -> String { text(p, en: "Category", es: "Categoría") }
    static func minimumRating(_ p: String) -> String { text(p, en: "Minimum rating", es: "Calificación mínima") }
    static func any(_ p: String) -> String { text(p, en: "Any", es: "Cualquiera") }
    static func turnOnFilters(_ p: String) -> String {
        text(p,
             en: "Turn on the filters you want to use.",
             es: "Activa los filtros que deseas usar.")
    }

    static func selectedForRoulette(_ p: String) -> String { text(p, en: "Selected for roulette", es: "Seleccionados para la ruleta") }
    static func selectedCountLabel(_ count: Int, _ p: String) -> String {
        isSpanish(p) ? "\(count) seleccionados" : "\(count) selected"
    }
    static func needAtLeastTwo(_ p: String) -> String {
        text(p,
             en: "Select at least 2 restaurants to start the roulette.",
             es: "Selecciona al menos 2 restaurantes para iniciar la ruleta.")
    }
    static func selectedWillBeUsed(_ p: String) -> String {
        text(p,
             en: "Your selected restaurants will be used in the roulette.",
             es: "Tus restaurantes seleccionados se usarán en la ruleta.")
    }
    static func maximumSelected(_ p: String) -> String { text(p, en: "Maximum selected", es: "Máximo seleccionado") }
    static func clearSelection(_ p: String) -> String { text(p, en: "Clear selection", es: "Limpiar selección") }
    static func chooseForMe(_ p: String) -> String { text(p, en: "Choose for me", es: "Elegir por mí") }
    static func availableChoices(_ count: Int, _ p: String) -> String {
        isSpanish(p) ? "Opciones disponibles: \(count)" : "Available choices: \(count)"
    }
    static func selectUpToTen(_ p: String) -> String {
        text(p, en: "Select up to 10 restaurants", es: "Selecciona hasta 10 restaurantes")
    }

    static func noRestaurantsYet(_ p: String) -> String {
        text(p, en: "No restaurants yet", es: "Aún no hay restaurantes")
    }
    static func noRestaurantsDesc(_ p: String) -> String {
        text(p,
             en: "Go to Restaurants to add places, then come back here to choose.",
             es: "Ve a Restaurantes para agregar lugares y luego regresa aquí para elegir.")
    }

    static func findRestaurantsNearYou(_ p: String) -> String {
        text(p, en: "Find restaurants near you", es: "Encuentra restaurantes cerca de ti")
    }
    static func nearbyIntro(_ p: String) -> String {
        text(p,
             en: "Use your current location to find nearby restaurants for a random lunch pick.",
             es: "Usa tu ubicación actual para encontrar restaurantes cercanos para una selección aleatoria de almuerzo.")
    }
    static func findNearbyRestaurants(_ p: String) -> String {
        text(p, en: "Find Nearby Restaurants", es: "Buscar Restaurantes Cercanos")
    }
    static func searchingNearby(_ p: String) -> String { text(p, en: "Searching nearby", es: "Buscando cercanos") }
    static func preparingNearbySearch(_ p: String) -> String {
        text(p, en: "Preparing nearby search...", es: "Preparando búsqueda cercana...")
    }
    static func gettingCurrentLocation(_ p: String) -> String {
        text(p, en: "Getting your current location...", es: "Obteniendo tu ubicación actual...")
    }
    static func searchingNearbyRestaurants(_ p: String) -> String {
        text(p, en: "Searching nearby restaurants...", es: "Buscando restaurantes cercanos...")
    }
    static func requestLocationPermission(_ p: String) -> String {
        text(p, en: "Requesting location permission...", es: "Solicitando permiso de ubicación...")
    }
    static func waitingPermission(_ p: String) -> String {
        text(p, en: "Waiting for location permission...", es: "Esperando permiso de ubicación...")
    }
    static func permissionGranted(_ p: String) -> String {
        text(p, en: "Permission granted. Starting nearby search...", es: "Permiso concedido. Iniciando búsqueda cercana...")
    }
    static func locationDenied(_ p: String) -> String {
        text(p,
             en: "Location access is denied. Enable it in Settings to use Nearby mode.",
             es: "El acceso a la ubicación está denegado. Actívalo en Ajustes para usar el modo Cercanos.")
    }
    static func nearbySearchTitle(_ p: String) -> String { text(p, en: "Nearby Search", es: "Búsqueda Cercana") }
    static func noNearbyFound(_ p: String) -> String {
        text(p, en: "No nearby restaurants were found.", es: "No se encontraron restaurantes cercanos.")
    }
    static func noNearbyMatchedFilters(_ p: String) -> String {
        text(p, en: "No nearby restaurants matched your current filters.", es: "Ningún restaurante cercano coincide con tus filtros actuales.")
    }
    static func foundNearbyCount(_ count: Int, _ p: String) -> String {
        if isSpanish(p) {
            return "Se encontraron \(count) restaurante\(count == 1 ? "" : "s") cercanos."
        } else {
            return "Found \(count) nearby restaurant\(count == 1 ? "" : "s")."
        }
    }

    static func selectionLimitTitle(_ p: String) -> String { text(p, en: "Selection Limit", es: "Límite de Selección") }
    static func selectionLimitMessage(_ p: String) -> String {
        text(p, en: "You can select up to 10 restaurants.", es: "Puedes seleccionar hasta 10 restaurantes.")
    }
    static func working(_ p: String) -> String { text(p, en: "Working...", es: "Trabajando...") }

    static func settings(_ p: String) -> String { text(p, en: "Settings", es: "Ajustes") }
    static func preferences(_ p: String) -> String { text(p, en: "Preferences", es: "Preferencias") }
    static func defaultRestaurantSource(_ p: String) -> String {
        text(p, en: "Default restaurant source", es: "Fuente predeterminada de restaurantes")
    }
    static func language(_ p: String) -> String { text(p, en: "Language", es: "Idioma") }
    static func system(_ p: String) -> String { text(p, en: "System", es: "Sistema") }
    static func english(_ p: String) -> String { text(p, en: "English", es: "Inglés") }
    static func spanish(_ p: String) -> String { text(p, en: "Spanish", es: "Español") }
    static func roulette(_ p: String) -> String { text(p, en: "Roulette", es: "Ruleta") }
    static func spinDuration(_ p: String) -> String { text(p, en: "Spin duration", es: "Duración del giro") }
    static func faster(_ p: String) -> String { text(p, en: "Faster", es: "Más rápido") }
    static func slower(_ p: String) -> String { text(p, en: "Slower", es: "Más lento") }
    static func foodTypes(_ p: String) -> String { text(p, en: "Food Types", es: "Tipos de Comida") }
    static func addNewFoodType(_ p: String) -> String { text(p, en: "Add new food type", es: "Agregar nuevo tipo de comida") }
    static func add(_ p: String) -> String { text(p, en: "Add", es: "Agregar") }
    static func about(_ p: String) -> String { text(p, en: "About", es: "Acerca de") }
    static func app(_ p: String) -> String { text(p, en: "App", es: "App") }
    static func version(_ p: String) -> String { text(p, en: "Version", es: "Versión") }

    static func restaurants(_ p: String) -> String { text(p, en: "Restaurants", es: "Restaurantes") }
    static func addRestaurant(_ p: String) -> String { text(p, en: "Add Restaurant", es: "Agregar Restaurante") }
    static func editRestaurant(_ p: String) -> String { text(p, en: "Edit Restaurant", es: "Editar Restaurante") }
    static func required(_ p: String) -> String { text(p, en: "Required", es: "Requerido") }
    static func photo(_ p: String) -> String { text(p, en: "Photo", es: "Foto") }
    static func choosePhoto(_ p: String) -> String { text(p, en: "Choose Photo", es: "Elegir Foto") }
    static func changePhoto(_ p: String) -> String { text(p, en: "Change Photo", es: "Cambiar Foto") }
    static func removePhoto(_ p: String) -> String { text(p, en: "Remove Photo", es: "Eliminar Foto") }
    static func noPhoto(_ p: String) -> String { text(p, en: "No photo", es: "Sin foto") }
    static func details(_ p: String) -> String { text(p, en: "Details", es: "Detalles") }
    static func name(_ p: String) -> String { text(p, en: "Name", es: "Nombre") }
    static func typeOfFood(_ p: String) -> String { text(p, en: "Type of food", es: "Tipo de comida") }
    static func none(_ p: String) -> String { text(p, en: "None", es: "Ninguno") }
    static func averageCost(_ p: String) -> String { text(p, en: "Average cost", es: "Costo promedio") }
    static func address(_ p: String) -> String { text(p, en: "Address", es: "Dirección") }
    static func ratingLabel(_ p: String) -> String { text(p, en: "Rating (0–5)", es: "Calificación (0–5)") }
    static func frequency(_ p: String) -> String { text(p, en: "Frequency", es: "Frecuencia") }
    static func distanceMiles(_ p: String) -> String { text(p, en: "Distance miles", es: "Distancia en millas") }
    static func save(_ p: String) -> String { text(p, en: "Save", es: "Guardar") }
    static func cancel(_ p: String) -> String { text(p, en: "Cancel", es: "Cancelar") }
    static func done(_ p: String) -> String { text(p, en: "Done", es: "Listo") }

    static func yourPick(_ p: String) -> String { text(p, en: "Your Pick", es: "Tu Selección") }
    static func selectedRestaurant(_ p: String) -> String { text(p, en: "Selected restaurant", es: "Restaurante seleccionado") }
    static func winning(_ p: String) -> String { text(p, en: "Winning", es: "Ganador") }
    static func mapPreview(_ p: String) -> String { text(p, en: "Map preview", es: "Vista del mapa") }
    static func distanceValue(_ miles: Double, _ p: String) -> String {
        let value = String(format: "%.1f", miles)
        return isSpanish(p) ? "\(value) millas" : "\(value) miles"
    }
    static func description(_ p: String) -> String { text(p, en: "Description", es: "Descripción") }
    static func saveToYourList(_ p: String) -> String { text(p, en: "Save to your list", es: "Guardar en tu lista") }
    static func saveLocalDesc(_ p: String) -> String {
        text(p,
             en: "Save this restaurant to your local list so it can appear again in Local mode.",
             es: "Guarda este restaurante en tu lista local para que pueda aparecer nuevamente en el modo Local.")
    }
    static func saved(_ p: String) -> String { text(p, en: "Saved", es: "Guardado") }
    static func saveRestaurant(_ p: String) -> String { text(p, en: "Save Restaurant", es: "Guardar Restaurante") }
    static func alreadyInLocal(_ p: String) -> String {
        text(p, en: "This restaurant is already in your local list.", es: "Este restaurante ya está en tu lista local.")
    }
    static func savedToLocal(_ p: String) -> String {
        text(p, en: "Restaurant saved to your local list.", es: "Restaurante guardado en tu lista local.")
    }
}
