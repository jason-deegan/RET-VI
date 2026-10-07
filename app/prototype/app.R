# RET-VI demonstration app - V4.2
# Synthetic values only.
#
# This is a UX / analytical wiring demonstration, not the final RET-VI model.
# All values, weights, standardisation, interpretation and geography are
# illustrative placeholders and must be replaced / validated before use.
#
# Dependencies:
#   shiny, bslib, leaflet, ggplot2

library(shiny)
library(bslib)
library(leaflet)
library(ggplot2)
library(csmaps)

# addResourcePath makes them available both locally and when published.
app_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
addResourcePath("retvi_assets", app_dir)

# -------------------------------------------------------------------------
# DEMONSTRATION DATA
# -------------------------------------------------------------------------

# Synthetic municipality-level demonstration profiles. These are deliberately
# illustrative, but now cover all 23 Rogaland municipalities so that the map
# can demonstrate a fuller regional pattern.
municipality_profiles <- data.frame(
  geography_id = c(
    "1101","1103","1106","1108","1111","1112","1114","1119",
    "1120","1121","1122","1124","1127","1130","1133","1134",
    "1135","1144","1145","1146","1149","1151","1160"
  ),
  geography_name = c(
    "Eigersund","Stavanger","Haugesund","Sandnes","Sokndal","Lund",
    "Bjerkreim","Haa","Klepp","Time","Gjesdal","Sola","Randaberg",
    "Strand","Hjelmeland","Suldal","Sauda","Kvitsoy","Bokn","Tysvaer",
    "Karmoy","Utsira","Vindafjord"
  ),
  exposure_target = c(
    46,78,70,63,42,38,35,45,52,50,48,72,58,45,30,34,41,39,50,60,66,36,43
  ),
  sensitivity_target = c(
    43,56,59,52,48,46,40,47,50,48,45,53,51,47,43,44,52,42,44,49,58,39,46
  ),
  capacity_target = c(
    55,38,43,50,47,52,60,55,58,57,55,44,53,52,58,56,50,62,54,51,44,65,54
  ),
  stringsAsFactors = FALSE
)

indicator_specs <- data.frame(
  indicator_id = c(
    "energy_employment_share",
    "energy_sector_specialisation",
    "energy_sector_age_profile",
    "energy_skill_profile",
    "wp1_skill_demand_green",
    "wp1_skill_supply_green",
    "wp1_skill_relatedness"
  ),
  indicator_name = c(
    "Energy employment share",
    "Energy-sector specialisation",
    "Energy-sector age profile",
    "Energy skill profile",
    "Green skill demand",
    "Green skill supply",
    "Skill relatedness"
  ),
  unit = c("share", "index", "share", "share", "index", "index", "index"),
  stringsAsFactors = FALSE
)

# Convert the illustrative dimension profiles into raw indicator values.
# The resulting values are synthetic and are only intended to demonstrate
# how municipality-level indicator evidence can feed the three dimensions.
demo <- do.call(
  rbind,
  lapply(seq_len(nrow(municipality_profiles)), function(i) {
    p <- municipality_profiles[i, ]
    data.frame(
      geography_id = p$geography_id,
      geography_name = p$geography_name,
      indicator_id = indicator_specs$indicator_id,
      indicator_name = indicator_specs$indicator_name,
      value = c(
        0.05 + p$exposure_target / 100 * 0.20,
        0.60 + p$exposure_target / 100 * 1.20,
        0.15 + p$sensitivity_target / 100 * 0.35,
        0.25 + p$sensitivity_target / 100 * 0.50,
        0.20 + p$capacity_target / 100 * 0.70,
        0.20 + p$capacity_target / 100 * 0.70,
        0.30 + p$capacity_target / 100 * 0.60
      ),
      unit = indicator_specs$unit,
      year = 2024,
      source = "SYNTHETIC DEMONSTRATION",
      quality_flag = "SYNTHETIC",
      notes = "Synthetic demonstration value only",
      stringsAsFactors = FALSE
    )
  })
)

# Municipality names are display labels only. Normalise them defensively
# for publishing environments with restrictive native encodings. Stable
# geography_id values remain the analytical keys throughout the app.
demo$geography_name <- iconv(
  demo$geography_name,
  from = "",
  to = "ASCII//TRANSLIT"
)

# -------------------------------------------------------------------------
# DEMONSTRATION STANDARDISATION
# -------------------------------------------------------------------------

normalise_demo <- function(x) {
  if (all(is.na(x))) return(rep(NA_real_, length(x)))
  if (max(x, na.rm = TRUE) == min(x, na.rm = TRUE)) {
    return(rep(50, length(x)))
  }
  100 * (x - min(x, na.rm = TRUE)) /
    (max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
}

demo$std <- ave(
  demo$value,
  demo$indicator_id,
  FUN = normalise_demo
)

demo$oriented <- demo$std

capacity_ids <- c(
  "wp1_skill_demand_green",
  "wp1_skill_supply_green",
  "wp1_skill_relatedness"
)

# Higher capacity is protective, so the capacity indicators are inverted
# for the illustrative vulnerability-oriented display.
demo$oriented[
  demo$indicator_id %in% capacity_ids
] <- 100 - demo$std[
  demo$indicator_id %in% capacity_ids
]

# -------------------------------------------------------------------------
# DIMENSION SCORES
# -------------------------------------------------------------------------

dimensions <- do.call(
  rbind,
  lapply(
    split(demo, demo$geography_id),
    function(x) {
      
      e <- mean(
        x$oriented[
          x$indicator_id %in%
            c(
              "energy_employment_share",
              "energy_sector_specialisation"
            )
        ],
        na.rm = TRUE
      )
      
      s <- mean(
        x$oriented[
          x$indicator_id %in%
            c(
              "energy_sector_age_profile",
              "energy_skill_profile"
            )
        ],
        na.rm = TRUE
      )
      
      # This is displayed as capacity: higher = more capacity.
      a <- mean(
        x$std[
          x$indicator_id %in% capacity_ids
        ],
        na.rm = TRUE
      )
      
      data.frame(
        geography_id = x$geography_id[1],
        geography_name = x$geography_name[1],
        Exposure = e,
        Sensitivity = s,
        Adaptive_Capacity = a,
        stringsAsFactors = FALSE
      )
    }
  )
)

rownames(dimensions) <- NULL

# -------------------------------------------------------------------------
# DEMONSTRATION SCORING
# -------------------------------------------------------------------------

scenario_composite <- function(exposure, sensitivity, capacity, weights) {
  vulnerability_capacity <- 100 - capacity
  
  exposure * weights["Exposure"] +
    sensitivity * weights["Sensitivity"] +
    vulnerability_capacity * weights["Capacity"]
}

balanced_weights <- c(
  Exposure = 1 / 3,
  Sensitivity = 1 / 3,
  Capacity = 1 / 3
)

dimensions$Demo_RET_VI <- apply(
  dimensions,
  1,
  function(x) {
    scenario_composite(
      as.numeric(x["Exposure"]),
      as.numeric(x["Sensitivity"]),
      as.numeric(x["Adaptive_Capacity"]),
      balanced_weights
    )
  }
)

# -------------------------------------------------------------------------
# OFFICIAL NORWEGIAN MUNICIPALITY GEOGRAPHY
# -------------------------------------------------------------------------
# The prototype uses the csmaps package, which provides municipality
# boundaries derived from Geonorge in a lightweight format that can be
# used directly with Leaflet. The 2024 boundary version is used here.
#
# Source/package:
#   csmaps::nor_municip_map_b2024_default_sf
#
# The RET-VI values remain synthetic. The geography is real.

# Rogaland's 2024 municipality codes and names.
rogaland_municipalities <- c(
  "1101" = "Eigersund",
  "1103" = "Stavanger",
  "1106" = "Haugesund",
  "1108" = "Sandnes",
  "1111" = "Sokndal",
  "1112" = "Lund",
  "1114" = "Bjerkreim",
  "1119" = "Haa",
  "1120" = "Klepp",
  "1121" = "Time",
  "1122" = "Gjesdal",
  "1124" = "Sola",
  "1127" = "Randaberg",
  "1130" = "Strand",
  "1133" = "Hjelmeland",
  "1134" = "Suldal",
  "1135" = "Sauda",
  "1144" = "Kvitsoy",
  "1145" = "Bokn",
  "1146" = "Tysvaer",
  "1149" = "Karmoy",
  "1151" = "Utsira",
  "1160" = "Vindafjord"
)

# Every Rogaland municipality is now part of the synthetic demonstration.
demo_name_by_id <- rogaland_municipalities

demo_id_by_name <- setNames(
  names(demo_name_by_id),
  unname(demo_name_by_id)
)

# Prefer the sf version for Leaflet. It preserves multipart municipality
# geometry correctly (important for coastal/island municipalities).
municip_map_all <- csmaps::nor_municip_map_b2024_default_sf

# csmaps documents the geometry column as `geometry`. Explicitly reset the
# sf geometry pointer before any column manipulation/subsetting. This avoids
# an sf-column attribute issue in some R/sf combinations.
if (!inherits(municip_map_all, "sf")) {
  stop("The csmaps municipality object is not an sf object.")
}
if (!"geometry" %in% names(municip_map_all)) {
  stop("The csmaps municipality sf object does not contain a `geometry` column.")
}
sf::st_geometry(municip_map_all) <- "geometry"

# csmaps stores the municipality identifier in `location_code`. Depending
# on how the package data are represented in the local R installation, this
# can arrive as numeric, character, or character-with-decimal formatting.
# Normalise it before matching to our stable municipality codes.
normalise_municipality_code <- function(x) {
  x <- trimws(as.character(x))
  
  # csmaps stores municipality identifiers in the form
  # "municip_nor1101", "municip_nor1103", etc.
  # Strip the package prefix first so the remaining value is the
  # stable Norwegian municipality code used elsewhere in RET-VI.
  x <- sub("^municip_nor", "", x, ignore.case = TRUE)
  
  # Be tolerant of numeric/decimal representations as well.
  x <- sub("\\.0+$", "", x)
  x <- sub("^0+", "", x)
  
  x[x == ""] <- NA_character_
  x
}

municip_map_all$location_code_raw <- municip_map_all$location_code
municip_map_all$location_code <- normalise_municipality_code(
  municip_map_all$location_code
)

# Use the normalised municipality codes for the prototype map.
# csmaps documents this field explicitly as the municipality code.
municip_map <- municip_map_all[
  municip_map_all$location_code %in% names(rogaland_municipalities),
  ,
  drop = FALSE
]

# Reassert the geometry column after subsetting. This is deliberately explicit
# because leaflet relies on the sf object having a valid sf_column attribute.
sf::st_geometry(municip_map) <- "geometry"

if (nrow(municip_map) == 0) {
  stop(
    paste0(
      "csmaps loaded, but no municipality codes matched the Rogaland ",
      "codes. The first location_code values in the installed dataset are: ",
      paste(utils::head(unique(municip_map_all$location_code), 20), collapse = ", "),
      "."
    )
  )
}

missing_rogaland <- setdiff(
  names(rogaland_municipalities),
  unique(municip_map$location_code)
)

if (length(missing_rogaland) > 0) {
  warning(
    paste0(
      "Some Rogaland municipality codes were not found in csmaps: ",
      paste(missing_rogaland, collapse = ", "),
      ". The map will use the municipalities that are available."
    )
  )
}

municip_map$geography_name <- unname(
  rogaland_municipalities[
    municip_map$location_code
  ]
)
municip_map$geography_name <- iconv(
  municip_map$geography_name,
  from = "",
  to = "ASCII//TRANSLIT"
)

# Geometry helper for one municipality. With the sf representation,
# multipart/coastal municipalities remain valid Leaflet geometries.
municipality_geometry <- function(code) {
  municip_map[
    municip_map$location_code == as.character(code),
    ,
    drop = FALSE
  ]
}

# -------------------------------------------------------------------------
# MAP COLOUR SYSTEM
# -------------------------------------------------------------------------

pal <- colorNumeric(
  palette = c(
    "#2c7bb6",
    "#abd9e9",
    "#ffffbf",
    "#fdae61",
    "#d7191c"
  ),
  domain = dimensions$Demo_RET_VI
)

score_colour <- function(score, capacity = FALSE) {
  
  vulnerability_score <- if (capacity) 100 - score else score
  
  rgb <- grDevices::colorRampPalette(
    c(
      "#2c7bb6",
      "#abd9e9",
      "#ffffbf",
      "#fdae61",
      "#d7191c"
    )
  )(101)
  
  rgb[
    max(
      1,
      min(
        101,
        round(vulnerability_score) + 1
      )
    )
  ]
}

# -------------------------------------------------------------------------
# MAP COLOUR SYSTEM
# -------------------------------------------------------------------------

pal <- colorNumeric(
  palette = c(
    "#2c7bb6",
    "#abd9e9",
    "#ffffbf",
    "#fdae61",
    "#d7191c"
  ),
  domain = dimensions$Demo_RET_VI
)

score_colour <- function(score, capacity = FALSE) {
  
  vulnerability_score <- if (capacity) 100 - score else score
  
  rgb <- grDevices::colorRampPalette(
    c(
      "#2c7bb6",
      "#abd9e9",
      "#ffffbf",
      "#fdae61",
      "#d7191c"
    )
  )(101)
  
  rgb[
    max(
      1,
      min(
        101,
        round(vulnerability_score) + 1
      )
    )
  ]
}

# -------------------------------------------------------------------------
# UI HELPERS
# -------------------------------------------------------------------------

score_card <- function(title, description, value_output) {
  card(
    class = "dimension-card",
    card_header(
      class = "dimension-card-header",
      title
    ),
    div(
      class = "dimension-card-body",
      p(
        class = "dimension-description",
        description
      ),
      uiOutput(value_output)
    )
  )
}

institution_links <- tags$span(class = "demo-label", "Research software demonstration")

# -------------------------------------------------------------------------
# UI
# -------------------------------------------------------------------------

ui <- page_navbar(
  id = "main_nav",
  title = tags$div(
    class = "navbar-brand-wrap",
    tags$span("RET-VI - demonstration"),
    institution_links
  ),
  
  theme = bs_theme(version = 5) |>
    bs_add_rules(paste0(
      ".navbar{",
      "position:relative;",
      "}",
      
      ".navbar-brand-wrap{",
      "display:flex;",
      "align-items:center;",
      "}",
      
      ".demo-label{",
      "font-size:.78rem;",
      "opacity:.75;",
      "margin-left:12px;",
      "}",
      
      ".demo-banner{",
      "background:#fff4cc;",
      "border:1px solid #e4c65a;",
      "border-radius:10px;",
      "padding:12px 16px;",
      "margin-bottom:18px;",
      "}",
      
      ".map-profile-row{",
      "width:100%;",
      "margin-bottom:18px !important;",
      "}",
      
      ".map-profile-row > .row{",
      "min-height:640px !important;",
      "align-items:stretch !important;",
      "}",
      
      ".map-card{",
      "min-height:640px !important;",
      "height:auto !important;",
      "overflow:visible !important;",
      "}",
      
      ".map-card .card-body{",
      "min-height:575px !important;",
      "height:auto !important;",
      "overflow:visible !important;",
      "}",
      
      ".map-card .leaflet-container{",
      "height:560px !important;",
      "min-height:560px !important;",
      "}",
      
      ".dimension-row{",
      "min-height:285px !important;",
      "margin-bottom:18px !important;",
      "position:relative;",
      "z-index:1;",
      "}",
      
      ".dimension-card{",
      "min-height:270px !important;",
      "height:270px !important;",
      "margin-bottom:0 !important;",
      "overflow:visible !important;",
      "}",
      
      ".dimension-card .card-body{",
      "height:auto !important;",
      "min-height:205px !important;",
      "overflow:visible !important;",
      "}",
      
      ".dimension-card-header{",
      "font-size:1.08rem;",
      "font-weight:650;",
      "padding:16px 18px;",
      "}",
      
      ".dimension-card-body{",
      "padding:20px;",
      "min-height:155px !important;",
      "height:auto !important;",
      "display:flex;",
      "flex-direction:column;",
      "justify-content:flex-start;",
      "overflow:visible !important;",
      "}",
      
      ".dimension-description{",
      "font-size:.92rem;",
      "line-height:1.1;",
      "color:#52606d;",
      "margin-bottom:6px;",
      "}",
      
      ".dimension-score{",
      "font-size:3.4rem;",
      "font-weight:750;",
      "line-height:1;",
      "margin-top:auto;",
      "}",
      
      ".demo-composite{",
      "font-size:3.2rem;",
      "font-weight:750;",
      "line-height:1;",
      "margin-top:6px;",
      "}",
      
      ".profile-card{",
      "min-height:640px !important;",
      "height:640px !important;",
      "overflow:visible !important;",
      "border:1px solid #e3e8ee;",
      "border-radius:10px;",
      "box-shadow:0 1px 3px rgba(15,23,42,.06);",
      "}",
      
      ".profile-card .card-body{",
      "padding:0 !important;",
      "height:100% !important;",
      "min-height:0 !important;",
      "display:flex;",
      "flex-direction:column;",
      "overflow:visible !important;",
      "}",
      
      ".profile-summary{",
      "padding:18px 18px 14px 18px;",
      "}",
      
      ".profile-kicker{",
      "font-size:.78rem;",
      "font-weight:650;",
      "color:#64748b;",
      "margin-bottom:4px;",
      "}",
      
      ".profile-name{",
      "font-size:1.42rem;",
      "font-weight:750;",
      "color:#17365d;",
      "line-height:1.1;",
      "margin-bottom:16px;",
      "}",
      
      ".profile-code{",
      "font-size:.9rem;",
      "font-weight:400;",
      "color:#52606d;",
      "}",
      
      ".profile-overall{",
      "display:flex;",
      "align-items:baseline;",
      "justify-content:space-between;",
      "margin-bottom:8px;",
      "}",
      
      ".profile-overall-label{",
      "font-size:.9rem;",
      "font-weight:650;",
      "color:#17365d;",
      "}",
      
      ".profile-overall-score{",
      "font-size:2.1rem;",
      "font-weight:800;",
      "line-height:1;",
      "}",
      
      ".profile-dimension-row{",
      "display:flex;",
      "justify-content:space-between;",
      "align-items:center;",
      "padding:7px 0;",
      "border-top:1px solid #edf0f3;",
      "font-size:.88rem;",
      "}",
      
      ".profile-dimension-row .label{",
      "color:#334e68;",
      "}",
      
      ".profile-dimension-row .value{",
      "font-weight:750;",
      "color:#17365d;",
      "}",
      
      ".profile-button{",
      "width:100%;",
      "margin-top:12px;",
      "font-weight:650;",
      "border-radius:7px;",
      "padding:9px 12px;",
      "}",
      ".profile-button-icon{",
      "display:inline-flex;",
      "align-items:flex-end;",
      "justify-content:center;",
      "gap:2px;",
      "width:14px;",
      "height:14px;",
      "margin-right:8px;",
      "vertical-align:-2px;",
      "}",
      ".profile-button-icon span{",
      "display:block;",
      "width:3px;",
      "background:currentColor;",
      "border-radius:1px;",
      "}",
      ".profile-button-icon span:nth-child(1){height:6px;}",
      ".profile-button-icon span:nth-child(2){height:10px;}",
      ".profile-button-icon span:nth-child(3){height:14px;}",
      ".profile-info-icon{",
      "display:inline-flex;",
      "align-items:center;",
      "justify-content:center;",
      "width:17px;",
      "height:17px;",
      "margin-right:5px;",
      "border-radius:50%;",
      "background:#17365d;",
      "color:#ffffff;",
      "font-size:.72rem;",
      "font-weight:800;",
      "font-family:Arial,sans-serif;",
      "vertical-align:1px;",
      "}" ,
      
      ".profile-data-box{",
      "margin:0 18px 14px 18px;",
      "padding:12px 12px 10px 12px;",
      "background:#f7f9fb;",
      "border:1px solid #edf0f3;",
      "border-radius:8px;",
      "font-size:.82rem;",
      "color:#52606d;",
      "}",
      
      ".profile-data-title{",
      "font-size:.9rem;",
      "font-weight:700;",
      "color:#17365d;",
      "margin-bottom:6px;",
      "}",
      
      ".profile-data-note{",
      "margin:0;",
      "line-height:1.35;",
      "}",
      
      ".profile-institutions{",
      "margin-top:auto;",
      "padding:12px 18px 16px 18px;",
      "display:flex;",
      "align-items:center;",
      "gap:14px;",
      "border-top:1px solid #f0f2f5;",
      "}",
      
      ".supporting-row{",
      "margin-top:0 !important;",
      "}",
      
      ".supporting-card{",
      "min-height:300px !important;",
      "height:auto !important;",
      "overflow:visible !important;",
      "}",
      
      ".supporting-card .card-body{",
      "height:auto !important;",
      "min-height:240px !important;",
      "overflow:visible !important;",
      "}",
      
      ".supporting-card table{",
      "width:100%;",
      "table-layout:auto;",
      "}",
      
      ".small{",
      "font-size:.86rem;",
      "}",
      
      ".scenario-weight-label{",
      "font-size:.88rem;",
      "font-weight:600;",
      "margin-bottom:7px;",
      "}",
      
      ".comparison-note{",
      "font-size:.88rem;",
      "color:#52606d;",
      "}",
      
      ".navbar-brand{",
      "padding-top:0;",
      "padding-bottom:0;",
      "}"
    )),
  
  # -----------------------------------------------------------------------
  # OVERVIEW
  # -----------------------------------------------------------------------
  
  nav_panel(
    "Overview",
    
    div(
      class = "demo-banner",
      tags$strong("Demonstration only"),
      tags$span(
        " All values, weights and standardisation are synthetic placeholders; the municipality geography is real."
      ),
      tags$span(
        class = "ms-1",
        "They will (of course) need to be replaced with the true analysis when available."
      )
    ),
    
    div(
      class = "map-profile-row",
      
      layout_columns(
        col_widths = c(8, 4),
        
        card(
          class = "map-card",
          card_header("Kommune overview"),
          p(
            class = "text-muted small",
            "Rogaland municipality boundaries with synthetic RET-VI values for all 23 kommuner."
          ),
          leafletOutput("ret_map", height = "560px"),
          p(
            class = "text-muted small mt-2 mb-0",
            tags$a(
              href = "https://www.csids.no/csmaps/",
              target = "_blank",
              "Boundary source: csmaps / Geonorge (2024)"
            )
          )
        ),
        
        card(
          class = "profile-card",
          div(
            class = "profile-summary",
            uiOutput("profile_summary")
          ),
          div(
            class = "profile-data-box",
            div(
              class = "profile-data-title",
              span(class = "profile-info-icon", "i"),
              " Data"
            ),
            p(
              class = "profile-data-note",
              "N.B. All values are synthetic and purely for demonstration purposes only."
            )
          ),
          div(
            class = "profile-institutions",
            p(
              class = "small text-muted mb-0",
              "Public demonstration using synthetic data."
            )
          )
        )
      )
    ),
    
    div(
      class = "dimension-row",
      
      layout_columns(
        col_widths = c(4, 4, 4),
        
        score_card(
          "Exposure",
          "How exposed to the energy transition is an area.",
          "exposure_score"
        ),
        
        score_card(
          "Sensitivity",
          "How strongly local structures may be affected by transition pressures.",
          "sensitivity_score"
        ),
        
        score_card(
          "Adaptive Capacity",
          "Resources and capabilities available to anticipate, absorb, adjust to or redirect change.",
          "capacity_score"
        )
      )
    ),
    
    div(
      class = "supporting-row",
      
      layout_columns(
        col_widths = c(6, 6),
        
        card(
          class = "supporting-card",
          card_header("What is driving the illustrative result?"),
          tableOutput("top_indicators")
        ),
        
        card(
          class = "supporting-card",
          card_header("How to read this demo"),
          p(
            "The eventual portal should let users move from a kommune-level result into the three dimensions and then into the underlying indicators."
          ),
          p(
            "The composite shown here is deliberately simple and provisional. It demonstrates the interface, not a validated RET-VI calculation."
          ),
          tags$span(
            class = "badge text-bg-light",
            "Synthetic data"
          )
        )
      )
    )
  ),
  
  # -----------------------------------------------------------------------
  # REGION
  # -----------------------------------------------------------------------
  
  nav_panel(
    "Region",
    value = "Region",
    
    sidebarLayout(
      sidebarPanel(
        selectInput(
          "region",
          "Select kommune",
          choices = unique(demo$geography_name)
        ),
        hr(),
        p(
          class = "text-muted small",
          "Selecting a municipality here also highlights it on the map."
        )
      ),
      
      mainPanel(
        card(
          card_header(textOutput("region_title")),
          tableOutput("region_dims")
        ),
        br(),
        card(
          card_header("Indicators"),
          tableOutput("region_indicators")
        )
      )
    )
  ),
  
  # -----------------------------------------------------------------------
  # COMPARE AND COMBINE
  # -----------------------------------------------------------------------
  
  nav_panel(
    "Compare & combine",
    
    div(
      class = "demo-banner",
      tags$strong("Illustrative comparison"),
      tags$span(
        " Select two or more kommuner to compare profiles or view a simple combined profile."
      ),
      tags$span(
        class = "ms-1",
        "The combined view is a simple unweighted mean for demonstration only."
      )
    ),
    
    layout_columns(
      col_widths = c(4, 8),
      
      card(
        card_header("Select kommuner"),
        
        selectizeInput(
          "compare_kommuner",
          "Kommuner",
          choices = unique(demo$geography_name),
          selected = c("Sandnes", "Stavanger"),
          multiple = TRUE,
          options = list(
            placeholder = "Select kommuner..."
          )
        ),
        
        checkboxInput(
          "show_combined",
          "Show combined profile",
          value = TRUE
        ),
        
        p(
          class = "comparison-note mt-3",
          "This can be used for an exploratory cluster of kommuner (for example Jaeren, Dalane etc). Right now the user can choose, but we can also make these groupings more formal in the portal."
        )
      ),
      
      card(
        card_header("Comparative profile"),
        tableOutput("comparison_table")
      )
    ),
    
    layout_columns(
      col_widths = c(7, 5),
      
      card(
        card_header("Dimension profile"),
        plotOutput(
          "comparison_plot",
          height = "360px"
        )
      ),
      
      card(
        card_header("Combined profile - interpretation"),
        uiOutput("comparison_interpretation")
      )
    )
  ),
  
  # -----------------------------------------------------------------------
  # SCENARIOS
  # -----------------------------------------------------------------------
  
  nav_panel(
    "Scenarios & future planning",
    
    div(
      class = "demo-banner",
      tags$strong("Methodological scenario tool"),
      tags$span(
        " Explore how the illustrative composite changes when different dimensions receive greater emphasis."
      )
    ),
    
    layout_columns(
      col_widths = c(4, 8),
      
      card(
        card_header("Scenario controls"),
        
        selectInput(
          "scenario_region",
          "Kommune",
          choices = unique(demo$geography_name),
          selected = "Stavanger"
        ),
        
        radioButtons(
          "scenario",
          "Scenario",
          choices = c(
            "Balanced dimensions" = "balanced",
            "Exposure emphasis" = "exposure",
            "Sensitivity emphasis" = "sensitivity",
            "Adaptive Capacity emphasis" = "capacity"
          ),
          selected = "balanced"
        ),
        
        sliderInput(
          "scenario_emphasis",
          "Emphasis on selected dimension",
          min = 33,
          max = 80,
          value = 50,
          step = 1,
          post = "%"
        ),
        
        uiOutput("scenario_weights"),
        
        tags$hr(),
        
        p(
          class = "text-muted small",
          tags$strong("Important: "),
          "These are methodological scenarios for exploring assumptions. They are not forecasts of future vulnerability."
        )
      ),
      
      card(
        card_header("Scenario result"),
        
        uiOutput("scenario_profile"),
        
        br(),
        
        plotOutput(
          "scenario_plot",
          height = "320px"
        )
      )
    )
  ),
  
  # -----------------------------------------------------------------------
  # DATA AND METHOD
  # -----------------------------------------------------------------------
  
  nav_panel(
    "Data & method",
    
    layout_columns(
      col_widths = c(6, 6),
      
      card(
        card_header("Analytical chain"),
        
        tags$img(
          src = "retvi_assets/analytical_chain.png",
          alt = "RET-VI analytical chain: Data, Indicators, Dimensions, RET-VI index, Interpretation",
          style = "width:100%; height:auto; display:block; margin-bottom:16px;"
        ),
        
        p(
          "Each stage makes the next stage interpretable: from source data, through indicators and the three vulnerability dimensions, to the composite index and its interpretation."
        )
      ),
      
      card(
        card_header("What is provisional in this demonstration?"),
        
        tags$ul(
          tags$li("Synthetic values"),
          tags$li("Official municipality boundaries for the map"),
          tags$li("Candidate indicator set"),
          tags$li("Directionality"),
          tags$li("Standardisation"),
          tags$li("Weights"),
          tags$li("Aggregation formula"),
          tags$li("Geography boundaries")
        )
      )
    ),
    
    card(
      card_header("Why the score should be interrogable"),
      
      p(
        "A production RET-VI result should not require the user to trust a single composite number."
      ),
      
      p(
        "The user should be able to move from a composite result to Exposure, Sensitivity and Adaptive Capacity, then into the indicators contributing to each dimension, and finally to the underlying data and methodological assumptions."
      ),
      
      p(
        "This demonstration therefore treats the composite as one layer in a wider analytical system rather than as the endpoint."
      )
    )
  ),
  
  # -----------------------------------------------------------------------
  # ASSUMPTIONS
  # -----------------------------------------------------------------------
  
  nav_panel(
    "Assumptions",
    
    card(
      card_header("What is provisional?"),
      
      tags$ul(
        tags$li("Synthetic values"),
        tags$li("Schematic demonstration geography"),
        tags$li("Indicator set"),
        tags$li("Directionality where context-dependent"),
        tags$li("Standardisation method"),
        tags$li("Weights"),
        tags$li("Aggregation formula"),
        tags$li("Geography boundaries")
      )
    ),
    
    card(
      card_header("Map note"),
      
      p(
        "The municipality boundaries in this demonstration are based on the csmaps 2024 municipality dataset derived from Geonorge. RET-VI values remain synthetic."
      ),
      
      p(
        "The prototype uses official-style municipality geometry for spatial orientation. A production version should use the agreed current boundary version and geography crosswalk."
      )
    )
  )
)

# -------------------------------------------------------------------------
# SERVER
# -------------------------------------------------------------------------

server <- function(input, output, session) {
  
  selected <- reactiveVal("Stavanger")
  
  # Stable geography ID for analytical filtering. Municipality names are
  # display labels only and are never used as grouping/join keys.
  selected_id <- reactive({
    unname(demo_id_by_name[selected()])
  })
  
  observeEvent(
    input$region,
    {
      selected(input$region)
    },
    ignoreInit = FALSE
  )
  
  observeEvent(
    input$scenario_region,
    {
      req(input$scenario_region)
      
      selected(input$scenario_region)
      
      updateSelectInput(
        session,
        "region",
        selected = input$scenario_region
      )
    },
    ignoreInit = TRUE
  )
  
  observeEvent(
    selected(),
    {
      req(selected())
      
      updateSelectInput(
        session,
        "scenario_region",
        selected = selected()
      )
    },
    ignoreInit = TRUE
  )
  
  # -----------------------------------------------------------------------
  # MAP
  # -----------------------------------------------------------------------
  
  output$ret_map <- renderLeaflet({
    
    m <- leaflet(
      options = leafletOptions(
        minZoom = 6,
        maxZoom = 12
      )
    ) |>
      addTiles(
        group = "OpenStreetMap",
        options = tileOptions(noWrap = TRUE)
      ) |>
      setView(
        lng = 5.95,
        lat = 59.10,
        zoom = 7.25
      )
    
    # Draw all Rogaland municipalities in a quiet neutral background.
    # The sf geometry avoids the multipart-polygon artefacts that can appear
    # when the csmaps long/lat table is passed directly to Leaflet.
    m <- m |>
      addPolygons(
        data = municip_map,
        fillColor = "#f1f3f5",
        fillOpacity = 0.82,
        color = "#aab2b8",
        weight = 1,
        opacity = 0.9,
        layerId = ~paste0("base_", location_code),
        label = ~geography_name,
        highlightOptions = highlightOptions(
          weight = 2,
          color = "#555555",
          bringToFront = TRUE
        )
      )
    
    # Overlay all 23 synthetic municipality scores.
    demo_map <- municip_map[municip_map$location_code %in% names(demo_name_by_id), ]
    demo_map$Demo_RET_VI <- dimensions$Demo_RET_VI[
      match(
        demo_map$location_code,
        dimensions$geography_id
      )
    ]
    demo_map$demo_name <- unname(
      demo_name_by_id[demo_map$location_code]
    )
    
    m <- m |>
      addPolygons(
        data = demo_map,
        fillColor = ~pal(Demo_RET_VI),
        fillOpacity = 0.78,
        color = "#ffffff",
        weight = 1.4,
        opacity = 1,
        layerId = ~demo_name,
        label = ~paste0(
          demo_name,
          " | Illustrative RET-VI: ",
          round(Demo_RET_VI, 1)
        ),
        popup = ~paste0(
          "<strong>",
          demo_name,
          "</strong><br>",
          "Illustrative RET-VI: ",
          round(Demo_RET_VI, 1),
          "<br><small>Synthetic demonstration value</small>"
        ),
        highlightOptions = highlightOptions(
          weight = 3,
          color = "#222222",
          bringToFront = TRUE
        )
      )
    
    m |>
      addScaleBar(
        position = "bottomleft",
        options = scaleBarOptions(imperial = FALSE)
      ) |>
      addLegend(
        position = "bottomright",
        pal = pal,
        values = dimensions$Demo_RET_VI,
        title = "Illustrative vulnerability",
        opacity = 0.9
      ) |>
      addControl(
        html = paste0(
          "<div style='background:rgba(255,255,255,.92);",
          "padding:7px 10px;border-radius:6px;",
          "font-size:11px;color:#5b6570;'>",
          "Municipality boundaries: csmaps / Geonorge (2024)",
          "</div>"
        ),
        position = "topright"
      )
  })
  
  observeEvent(
    input$ret_map_shape_click,
    {
      click <- input$ret_map_shape_click
      
      if (
        !is.null(click$id) &&
        click$id %in% unique(demo$geography_name)
      ) {
        selected(click$id)
        
        updateSelectInput(
          session,
          "region",
          selected = click$id
        )
      }
    }
  )
  
  observeEvent(
    input$view_full_profile,
    {
      req(selected())
      updateSelectInput(
        session,
        "region",
        selected = selected()
      )
      nav_select(
        "main_nav",
        selected = "Region"
      )
    }
  )
  
  observe({
    req(selected())
    
    code <- unname(
      demo_id_by_name[
        selected()
      ]
    )
    
    g <- municipality_geometry(code)
    
    leafletProxy("ret_map") |>
      clearGroup("selection") |>
      addPolygons(
        data = g,
        group = "selection",
        fill = FALSE,
        color = "#111111",
        weight = 4,
        opacity = 0.95
      )
  })
  
  # -----------------------------------------------------------------------
  # SELECTED REGION
  # -----------------------------------------------------------------------
  
  reg <- reactive({
    demo[
      demo$geography_id == selected_id(),
      ,
      drop = FALSE
    ]
  })
  
  output$profile_title <- renderText({
    selected()
  })
  
  output$region_title <- renderText({
    paste("Illustrative profile -", selected())
  })
  
  # -----------------------------------------------------------------------
  # PROFILE
  # -----------------------------------------------------------------------
  
  output$profile_summary <- renderUI({
    
    d <- dimensions[
      dimensions$geography_id == selected_id(),
      ,
      drop = FALSE
    ]
    
    score <- scenario_composite(
      d$Exposure,
      d$Sensitivity,
      d$Adaptive_Capacity,
      balanced_weights
    )
    
    div(
      class = "profile-summary-inner",
      div(class = "profile-kicker", "Selected municipality"),
      div(
        class = "profile-name",
        selected(),
        span(
          class = "profile-code",
          paste0(" (", unname(demo_id_by_name[selected()]), ")")
        )
      ),
      div(
        class = "profile-overall",
        div(class = "profile-overall-label", "Overall RET-VI"),
        div(
          class = "profile-overall-score",
          style = paste0("color:", score_colour(score), ";"),
          round(score, 0)
        )
      ),
      div(
        class = "profile-dimension-row",
        span(class = "label", "Exposure"),
        span(class = "value", round(d$Exposure, 0))
      ),
      div(
        class = "profile-dimension-row",
        span(class = "label", "Sensitivity"),
        span(class = "value", round(d$Sensitivity, 0))
      ),
      div(
        class = "profile-dimension-row",
        span(class = "label", "Adaptive Capacity"),
        span(class = "value", round(d$Adaptive_Capacity, 0))
      ),
      actionButton(
        "view_full_profile",
        tagList(
          span(
            class = "profile-button-icon",
            span(), span(), span()
          ),
          "View full profile >"
        ),
        class = "btn-primary profile-button"
      )
    )
  })
  
  # -----------------------------------------------------------------------
  # DIMENSION CARDS
  # -----------------------------------------------------------------------
  
  output$exposure_score <- renderUI({
    
    score <- dimensions$Exposure[
      dimensions$geography_id == selected_id()
    ]
    
    tags$div(
      class = "dimension-score",
      style = paste0(
        "color:",
        score_colour(score),
        ";"
      ),
      round(score, 0)
    )
  })
  
  output$sensitivity_score <- renderUI({
    
    score <- dimensions$Sensitivity[
      dimensions$geography_id == selected_id()
    ]
    
    tags$div(
      class = "dimension-score",
      style = paste0(
        "color:",
        score_colour(score),
        ";"
      ),
      round(score, 0)
    )
  })
  
  output$capacity_score <- renderUI({
    
    score <- dimensions$Adaptive_Capacity[
      dimensions$geography_id == selected_id()
    ]
    
    tags$div(
      class = "dimension-score",
      style = paste0(
        "color:",
        score_colour(score, capacity = TRUE),
        ";"
      ),
      round(score, 0)
    )
  })
  
  # -----------------------------------------------------------------------
  # INDICATOR TABLE
  # -----------------------------------------------------------------------
  
  output$top_indicators <- renderTable({
    
    x <- reg()[
      ,
      c(
        "indicator_name",
        "value",
        "unit",
        "year"
      )
    ]
    
    names(x) <- c(
      "Indicator",
      "Value",
      "Unit",
      "Year"
    )
    
    x
    
  }, striped = TRUE, bordered = FALSE, spacing = "xs")
  
  # -----------------------------------------------------------------------
  # REGION TABLES
  # -----------------------------------------------------------------------
  
  output$region_dims <- renderTable({
    
    d <- dimensions[
      dimensions$geography_id == selected_id(),
      ,
      drop = FALSE
    ]
    
    data.frame(
      Dimension = c(
        "Exposure",
        "Sensitivity",
        "Adaptive Capacity",
        "Illustrative composite"
      ),
      Score = round(
        c(
          d$Exposure,
          d$Sensitivity,
          d$Adaptive_Capacity,
          scenario_composite(
            d$Exposure,
            d$Sensitivity,
            d$Adaptive_Capacity,
            balanced_weights
          )
        ),
        1
      )
    )
    
  }, striped = TRUE, bordered = TRUE)
  
  output$region_indicators <- renderTable({
    
    reg()[
      ,
      c(
        "indicator_name",
        "value",
        "unit",
        "year",
        "source",
        "quality_flag",
        "notes"
      )
    ]
    
  }, striped = TRUE)
  
  # -----------------------------------------------------------------------
  # COMPARE & COMBINE
  # -----------------------------------------------------------------------
  
  comparison_data <- reactive({
    
    req(input$compare_kommuner)
    
    selected_data <- dimensions[
      dimensions$geography_id %in% unname(demo_id_by_name[input$compare_kommuner]),
      ,
      drop = FALSE
    ]
    
    individual <- data.frame(
      Geography = selected_data$geography_name,
      Exposure = selected_data$Exposure,
      Sensitivity = selected_data$Sensitivity,
      `Adaptive Capacity` = selected_data$Adaptive_Capacity,
      `Illustrative RET-VI` = mapply(
        scenario_composite,
        selected_data$Exposure,
        selected_data$Sensitivity,
        selected_data$Adaptive_Capacity,
        MoreArgs = list(weights = balanced_weights)
      ),
      check.names = FALSE,
      stringsAsFactors = FALSE
    )
    
    if (isTRUE(input$show_combined)) {
      
      combined <- data.frame(
        Geography = "Selected group",
        Exposure = mean(selected_data$Exposure, na.rm = TRUE),
        Sensitivity = mean(selected_data$Sensitivity, na.rm = TRUE),
        `Adaptive Capacity` = mean(
          selected_data$Adaptive_Capacity,
          na.rm = TRUE
        ),
        `Illustrative RET-VI` = mean(
          mapply(
            scenario_composite,
            selected_data$Exposure,
            selected_data$Sensitivity,
            selected_data$Adaptive_Capacity,
            MoreArgs = list(weights = balanced_weights)
          ),
          na.rm = TRUE
        ),
        check.names = FALSE,
        stringsAsFactors = FALSE
      )
      
      rbind(individual, combined)
      
    } else {
      
      individual
    }
  })
  
  output$comparison_table <- renderTable({
    
    d <- comparison_data()
    
    d[, c(
      "Geography",
      "Exposure",
      "Sensitivity",
      "Adaptive Capacity",
      "Illustrative RET-VI"
    )]
    
  }, striped = TRUE, bordered = TRUE, digits = 1)
  
  output$comparison_plot <- renderPlot({
    
    d <- comparison_data()
    
    plot_data <- rbind(
      data.frame(
        Geography = d$Geography,
        Dimension = "Exposure",
        Score = d$Exposure
      ),
      data.frame(
        Geography = d$Geography,
        Dimension = "Sensitivity",
        Score = d$Sensitivity
      ),
      data.frame(
        Geography = d$Geography,
        Dimension = "Adaptive Capacity",
        Score = d$`Adaptive Capacity`
      )
    )
    
    ggplot(
      plot_data,
      aes(
        x = Geography,
        y = Score,
        fill = Dimension
      )
    ) +
      geom_col(
        position = position_dodge(width = 0.75),
        width = 0.68
      ) +
      coord_cartesian(ylim = c(0, 100)) +
      labs(
        x = NULL,
        y = "Score (0-100)",
        fill = NULL
      ) +
      theme_minimal(base_size = 13) +
      theme(
        legend.position = "top",
        axis.text.x = element_text(
          angle = 25,
          hjust = 1
        ),
        panel.grid.minor = element_blank()
      )
  })
  
  output$comparison_interpretation <- renderUI({
    
    req(input$compare_kommuner)
    
    d <- dimensions[
      dimensions$geography_id %in% unname(demo_id_by_name[input$compare_kommuner]),
      ,
      drop = FALSE
    ]
    
    scores <- c(
      Exposure = mean(d$Exposure, na.rm = TRUE),
      Sensitivity = mean(d$Sensitivity, na.rm = TRUE),
      `Adaptive Capacity vulnerability signal` =
        mean(100 - d$Adaptive_Capacity, na.rm = TRUE)
    )
    
    strongest <- names(scores)[which.max(scores)]
    
    strongest_label <- switch(
      strongest,
      "Exposure" = "Exposure",
      "Sensitivity" = "Sensitivity",
      "Adaptive Capacity vulnerability signal" = "Adaptive Capacity"
    )
    
    tagList(
      p(
        paste(
          "Across the selected kommuner, the strongest illustrative vulnerability signal is",
          strongest_label,
          ""
        )
      ),
      
      p(
        "The combined profile is a descriptive average of the selected kommuner. In a production version, a regional aggregation method would need to be justified."
      ),
      
      tags$span(
        class = "badge text-bg-light",
        "Exploratory grouping - not a formal regional classification"
      )
    )
  })
  
  # -----------------------------------------------------------------------
  # SCENARIOS
  # -----------------------------------------------------------------------
  
  scenario_weights <- reactive({
    
    scenario <- input$scenario
    
    if (scenario == "balanced") {
      return(
        c(
          Exposure = 1 / 3,
          Sensitivity = 1 / 3,
          Capacity = 1 / 3
        )
      )
    }
    
    emphasis <- input$scenario_emphasis / 100
    remaining <- (1 - emphasis) / 2
    
    if (scenario == "exposure") {
      return(
        c(
          Exposure = emphasis,
          Sensitivity = remaining,
          Capacity = remaining
        )
      )
    }
    
    if (scenario == "sensitivity") {
      return(
        c(
          Exposure = remaining,
          Sensitivity = emphasis,
          Capacity = remaining
        )
      )
    }
    
    c(
      Exposure = remaining,
      Sensitivity = remaining,
      Capacity = emphasis
    )
  })
  
  output$scenario_weights <- renderUI({
    
    w <- scenario_weights()
    
    tagList(
      p(
        class = "scenario-weight-label",
        paste0(
          "Exposure: ",
          round(w["Exposure"] * 100),
          "% | Sensitivity: ",
          round(w["Sensitivity"] * 100),
          "% | Adaptive Capacity: ",
          round(w["Capacity"] * 100),
          "%"
        )
      ),
      
      div(
        class = "progress",
        style = "height:10px;",
        
        div(
          class = "progress-bar",
          style = paste0(
            "width:",
            w["Exposure"] * 100,
            "%;"
          )
        ),
        
        div(
          class = "progress-bar bg-warning",
          style = paste0(
            "width:",
            w["Sensitivity"] * 100,
            "%;"
          )
        ),
        
        div(
          class = "progress-bar bg-success",
          style = paste0(
            "width:",
            w["Capacity"] * 100,
            "%;"
          )
        )
      )
    )
  })
  
  output$scenario_profile <- renderUI({
    
    d <- dimensions[
      dimensions$geography_id == selected_id(),
      ,
      drop = FALSE
    ]
    
    w <- scenario_weights()
    
    score <- scenario_composite(
      d$Exposure,
      d$Sensitivity,
      d$Adaptive_Capacity,
      w
    )
    
    scenario_label <- switch(
      input$scenario,
      balanced = "Balanced dimensions",
      exposure = "Exposure emphasis",
      sensitivity = "Sensitivity emphasis",
      capacity = "Adaptive Capacity emphasis"
    )
    
    tagList(
      p(
        class = "text-muted small",
        "Selected kommune:"
      ),
      
      h3(selected()),
      
      div(
        class = "demo-composite",
        style = paste0(
          "color:",
          score_colour(score),
          ";"
        ),
        round(score, 0)
      ),
      
      p(
        class = "text-muted small",
        "Illustrative composite under the selected scenario."
      ),
      
      tags$hr(),
      
      p(
        class = "small",
        tags$strong("Scenario: "),
        scenario_label
      ),
      
      p(
        class = "small",
        "The underlying indicators do not change. Only the relative weighting of the three dimensions changes."
      )
    )
  })
  
  output$scenario_plot <- renderPlot({
    
    d <- dimensions[
      dimensions$geography_id == selected_id(),
      ,
      drop = FALSE
    ]
    
    w <- scenario_weights()
    
    baseline <- scenario_composite(
      d$Exposure,
      d$Sensitivity,
      d$Adaptive_Capacity,
      balanced_weights
    )
    
    scenario_score <- scenario_composite(
      d$Exposure,
      d$Sensitivity,
      d$Adaptive_Capacity,
      w
    )
    
    plot_data <- data.frame(
      Specification = c(
        "Balanced",
        "Selected scenario"
      ),
      Score = c(
        baseline,
        scenario_score
      )
    )
    
    ggplot(
      plot_data,
      aes(
        x = Specification,
        y = Score
      )
    ) +
      geom_col(
        width = 0.55
      ) +
      geom_text(
        aes(
          label = round(Score, 1)
        ),
        vjust = -0.4,
        size = 5
      ) +
      coord_cartesian(
        ylim = c(
          0,
          max(100, max(plot_data$Score, na.rm = TRUE) + 10)
        )
      ) +
      labs(
        x = NULL,
        y = "Illustrative RET-VI"
      ) +
      theme_minimal(base_size = 13) +
      theme(
        panel.grid.minor = element_blank()
      )
  })
}

shinyApp(ui, server)
