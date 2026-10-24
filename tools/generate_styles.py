#!/usr/bin/env python3
"""Genera gli stili MapLibre (mappa + globo) per tutti i temi di GassMaps.

Uso:  python3 tools/generate_styles.py
Scrive i file in GassMaps/Styles/<id>.json e GassMaps/Styles/<id>_globe.json
Fonte dati: OpenFreeMap (schema OpenMapTiles) - gratuita, senza API key.
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "GassMaps", "Styles")

SOURCE = {"type": "vector", "url": "https://tiles.openfreemap.org/planet"}
GLYPHS = "https://tiles.openfreemap.org/fonts/{fontstack}/{range}.pbf"
BOLD = ["Noto Sans Bold"]
REG = ["Noto Sans Regular"]
ITAL = ["Noto Sans Italic"]

NAME = ["coalesce", ["get", "name:it"], ["get", "name:latin"], ["get", "name"]]
NAME_EN = ["coalesce", ["get", "name:en"], ["get", "name:latin"], ["get", "name"]]

THEMES = {
    # ex "Saint Denis II" -> seppia western
    "dust": dict(
        land="#d6c19a", wood="#c9b287", grass="#cfb98f", sand="#e0cda6", ice="#efe6d2",
        park="#c5ae80", water="#a99f86", waterway="#9c927a", building="#bfa77c",
        building_top="#cbb489", minor="#f1e4c4", major="#f6ead0", motor="#fbf1dc",
        path="#e6d6b2", rail="#8f7b58", boundary="#7a6646", label="#3d2b16",
        halo="#e3d1ac", road_label="#3d2b16", road_halo="#efe1c0", house="#8a7550",
        water_label="#6b604a", shield="#7a5a2e", oneway=0.0, transform="uppercase",
    ),
    # ex "Los Santas" -> noir urbano (tema predefinito)
    "noir": dict(
        land="#303030", wood="#2e302e", grass="#2f312f", sand="#343332", ice="#4a4f53",
        park="#2d2f2d", water="#36414a", waterway="#36414a", building="#1b1b1b",
        building_top="#202020", minor="#a9a9a9", major="#ababab", motor="#b4b4b4",
        path="#6e6e6e", rail="#5c5c5c", boundary="#8a8a8a", label="#fcfcfc",
        halo="#000000", road_label="#fcfcfc", road_halo="#000000", house="#a0a0a0",
        water_label="#9fb2bf", shield="#2f47c9", oneway=0.8, transform="uppercase",
    ),
    # ex "PipBoy" -> terminale verde
    "bunker": dict(
        land="#061206", wood="#071707", grass="#071607", sand="#081808", ice="#0d260d",
        park="#082008", water="#020a02", waterway="#0a3a0a", building="#0b2a0b",
        building_top="#0f360f", minor="#1f9e1f", major="#2ccf2c", motor="#45ff45",
        path="#157015", rail="#1b7f1b", boundary="#2ccf2c", label="#5dff5d",
        halo="#000000", road_label="#7dff7d", road_halo="#000000", house="#2a9a2a",
        water_label="#3fcf3f", shield="#0f5f0f", oneway=0.6, transform="uppercase",
    ),
    # ex "Pixel Map" -> mondo a blocchi
    "pixel": dict(
        land="#79b64c", wood="#4f8f2f", grass="#7fc152", sand="#ddd08f", ice="#f4f7f7",
        park="#5ea338", water="#3d3ad6", waterway="#3d3ad6", building="#8c8c8c",
        building_top="#a3a3a3", minor="#c8b88a", major="#d9c896", motor="#e8d9a5",
        path="#a8996c", rail="#6b5a3a", boundary="#c0392b", label="#ffffff",
        halo="#1d1d4a", road_label="#ffffff", road_halo="#3a3a3a", house="#e9f3dd",
        water_label="#9fd1ff", shield="#3d3ad6", oneway=0.5, transform="none",
    ),
    # ex "Night City" -> distretto al neon
    "neon": dict(
        land="#0e0a12", wood="#100c14", grass="#100c15", sand="#130e16", ice="#1a1424",
        park="#120f1a", water="#081221", waterway="#0b1a33", building="#1b1024",
        building_top="#2a1838", minor="#b0205f", major="#ff2e7e", motor="#ff5fa2",
        path="#6a1640", rail="#3fd8ff", boundary="#c9a040", label="#3ff2ff",
        halo="#000000", road_label="#bff9ff", road_halo="#000000", house="#7a5c8c",
        water_label="#3f8fbf", shield="#ff2e7e", oneway=0.6, transform="uppercase",
    ),
    # ex "San Andrias" -> costa soleggiata
    "palm": dict(
        land="#86a072", wood="#6f8c5c", grass="#8daa76", sand="#cdbf94", ice="#e8eef0",
        park="#77955f", water="#6a92b8", waterway="#6a92b8", building="#9b9886",
        building_top="#aeab98", minor="#e9e5d6", major="#f2eedf", motor="#fff8e3",
        path="#c9c4b0", rail="#5b5b55", boundary="#4f4f4f", label="#ffffff",
        halo="#1c1c1c", road_label="#ffffff", road_halo="#2a2a2a", house="#f0f0e8",
        water_label="#e6f2ff", shield="#2f47c9", oneway=0.6, transform="uppercase",
    ),
    # ex "Heat Racing" -> viola notturno
    "heat": dict(
        land="#3a1162", wood="#341058", grass="#3f1569", sand="#4c1f78", ice="#c9b3ff",
        park="#43176f", water="#170a3d", waterway="#22105a", building="#4b1c7c",
        building_top="#5d2793", minor="#b98cff", major="#d7b8ff", motor="#f0e2ff",
        path="#7d52b8", rail="#9a7ad0", boundary="#d7b8ff", label="#ffffff",
        halo="#22003f", road_label="#ffffff", road_halo="#22003f", house="#cdb5f2",
        water_label="#b49cff", shield="#ff3d8b", oneway=0.6, transform="uppercase",
    ),
    # ex "The Rivia III" -> pergamena medievale
    "kingdom": dict(
        land="#b8925a", wood="#a6844f", grass="#b38f58", sand="#c7a46c", ice="#e3d3b0",
        park="#a5864f", water="#6f7a62", waterway="#66705a", building="#8f6c3c",
        building_top="#9c7845", minor="#e5cf9f", major="#ecd8ab", motor="#f3e2bb",
        path="#a8895a", rail="#4a3520", boundary="#4a3520", label="#2b1b0b",
        halo="#d9bb85", road_label="#2b1b0b", road_halo="#e2c895", house="#5a4122",
        water_label="#e8dcc0", shield="#5a4122", oneway=0.0, transform="none",
    ),
}


def interp(stops, base=1.5):
    expr = ["interpolate", ["exponential", base], ["zoom"]]
    for z, v in stops:
        expr += [z, v]
    return expr


def cls(*names):
    return ["match", ["get", "class"], list(names), True, False]


def road_line(lid, p, classes, color, widths, minzoom=0, dash=None, opacity=1.0):
    layer = {
        "id": lid,
        "type": "line",
        "source": "openmaptiles",
        "source-layer": "transportation",
        "minzoom": minzoom,
        "filter": ["all", cls(*classes), ["!=", ["get", "brunnel"], "tunnel"]],
        "layout": {"line-cap": "butt" if dash else "round", "line-join": "round"},
        "paint": {"line-color": color, "line-width": interp(widths), "line-opacity": opacity},
    }
    if dash:
        layer["paint"]["line-dasharray"] = dash
    return layer


def map_style(tid, p):
    layers = [
        {"id": "background", "type": "background", "paint": {"background-color": p["land"]}},
        {
            "id": "landcover-ice", "type": "fill", "source": "openmaptiles", "source-layer": "landcover",
            "filter": cls("ice"), "paint": {"fill-color": p["ice"]},
        },
        {
            "id": "landcover-sand", "type": "fill", "source": "openmaptiles", "source-layer": "landcover",
            "filter": cls("sand"), "paint": {"fill-color": p["sand"]},
        },
        {
            "id": "landcover-wood", "type": "fill", "source": "openmaptiles", "source-layer": "landcover",
            "filter": cls("wood", "forest"), "paint": {"fill-color": p["wood"], "fill-opacity": 0.9},
        },
        {
            "id": "landcover-grass", "type": "fill", "source": "openmaptiles", "source-layer": "landcover",
            "filter": cls("grass", "farmland", "scrub"), "paint": {"fill-color": p["grass"], "fill-opacity": 0.8},
        },
        {
            "id": "park", "type": "fill", "source": "openmaptiles", "source-layer": "park",
            "paint": {"fill-color": p["park"], "fill-opacity": 0.9},
        },
        {
            "id": "water", "type": "fill", "source": "openmaptiles", "source-layer": "water",
            "paint": {"fill-color": p["water"], "fill-antialias": True},
        },
        {
            "id": "waterway", "type": "line", "source": "openmaptiles", "source-layer": "waterway",
            "paint": {"line-color": p["waterway"], "line-width": interp([(8, 0.5), (14, 2), (18, 6)])},
        },
        {
            "id": "boundary-state", "type": "line", "source": "openmaptiles", "source-layer": "boundary",
            "filter": ["all", ["==", ["get", "admin_level"], 4], ["!=", ["get", "maritime"], 1]],
            "paint": {"line-color": p["boundary"], "line-opacity": 0.35, "line-dasharray": [3, 2],
                      "line-width": interp([(3, 0.4), (10, 1.2)])},
        },
        {
            "id": "boundary-country", "type": "line", "source": "openmaptiles", "source-layer": "boundary",
            "filter": ["all", ["==", ["get", "admin_level"], 2], ["!=", ["get", "maritime"], 1]],
            "paint": {"line-color": p["boundary"], "line-opacity": 0.7,
                      "line-width": interp([(2, 0.6), (8, 1.6), (12, 2.4)])},
        },
        road_line("road-path", p, ["path", "track"], p["path"], [(14, 0.5), (18, 3)], minzoom=15, dash=[2, 1.5]),
        road_line("road-rail", p, ["rail", "transit"], p["rail"], [(12, 0.6), (18, 3)], minzoom=12, dash=[3, 2]),
        road_line("road-service", p, ["service"], p["minor"], [(14, 0.6), (16, 2.5), (18, 7)], minzoom=14, opacity=0.85),
        road_line("road-minor", p, ["minor"], p["minor"], [(12, 0.5), (14, 1.6), (16, 5.5), (18, 16), (20, 40)], minzoom=12),
        road_line("road-secondary", p, ["secondary", "tertiary"], p["major"],
                  [(8, 0.5), (12, 1.6), (14, 3.5), (16, 8), (18, 20), (20, 48)], minzoom=8),
        road_line("road-primary", p, ["primary", "trunk"], p["major"],
                  [(5, 0.5), (10, 1.6), (14, 5), (16, 10), (18, 24), (20, 56)], minzoom=5),
        road_line("road-motorway", p, ["motorway"], p["motor"],
                  [(4, 0.6), (10, 2), (14, 6), (16, 12), (18, 28), (20, 64)], minzoom=4),
        {
            "id": "building-3d", "type": "fill-extrusion", "source": "openmaptiles", "source-layer": "building",
            "minzoom": 14,
            "paint": {
                "fill-extrusion-color": p["building"],
                "fill-extrusion-height": ["interpolate", ["linear"], ["zoom"], 14, 0, 15.5,
                                          ["to-number", ["get", "render_height"], 8]],
                "fill-extrusion-base": ["to-number", ["get", "render_min_height"], 0],
                "fill-extrusion-opacity": 0.92,
                "fill-extrusion-vertical-gradient": True,
            },
        },
        {
            "id": "road-oneway", "type": "symbol", "source": "openmaptiles", "source-layer": "transportation",
            "minzoom": 16,
            "filter": ["match", ["get", "oneway"], [1, -1], True, False],
            "layout": {
                "symbol-placement": "line", "symbol-spacing": 90, "icon-image": "gm-oneway",
                "icon-size": interp([(16, 0.55), (19, 0.9)]),
                "icon-rotate": ["match", ["get", "oneway"], -1, 180, 0],
                "icon-rotation-alignment": "map", "icon-allow-overlap": False,
            },
            "paint": {"icon-opacity": p["oneway"]},
        },
        {
            "id": "housenumber", "type": "symbol", "source": "openmaptiles", "source-layer": "housenumber",
            "minzoom": 17,
            "layout": {"text-field": ["get", "housenumber"], "text-font": BOLD, "text-size": 10},
            "paint": {"text-color": p["house"], "text-halo-color": p["halo"], "text-halo-width": 0.6},
        },
        {
            "id": "water-label", "type": "symbol", "source": "openmaptiles", "source-layer": "water_name",
            "layout": {"text-field": NAME, "text-font": ITAL, "text-size": 13, "text-letter-spacing": 0.2,
                       "text-transform": p["transform"], "text-max-width": 6},
            "paint": {"text-color": p["water_label"], "text-halo-color": p["halo"], "text-halo-width": 0.6},
        },
        {
            "id": "road-shield", "type": "symbol", "source": "openmaptiles", "source-layer": "transportation_name",
            "minzoom": 11,
            "filter": ["all", ["has", "ref"], ["<=", ["to-number", ["get", "ref_length"], 9], 6]],
            "layout": {
                "symbol-placement": "point", "symbol-spacing": 400,
                "text-field": ["get", "ref"], "text-font": BOLD, "text-size": 9,
                "icon-image": "gm-shield", "icon-text-fit": "both", "icon-text-fit-padding": [2, 4, 2, 4],
                "text-rotation-alignment": "viewport", "icon-rotation-alignment": "viewport",
            },
            "paint": {"text-color": "#ffffff"},
        },
        {
            "id": "road-label", "type": "symbol", "source": "openmaptiles", "source-layer": "transportation_name",
            "minzoom": 14,
            "layout": {
                "symbol-placement": "line", "text-field": NAME, "text-font": BOLD,
                "text-size": interp([(14, 9), (16, 11), (18, 14)]), "text-transform": p["transform"],
                "text-letter-spacing": 0.04, "text-rotation-alignment": "map", "text-pitch-alignment": "viewport",
            },
            "paint": {"text-color": p["road_label"], "text-halo-color": p["road_halo"], "text-halo-width": 1.4},
        },
        {
            "id": "poi", "type": "symbol", "source": "openmaptiles", "source-layer": "poi",
            "minzoom": 15,
            "filter": ["<=", ["to-number", ["get", "rank"], 30], 22],
            "layout": {
                "icon-image": [
                    "match", ["get", "class"],
                    ["park", "garden"], "gm-poi-park",
                    ["cinema", "theatre"], "gm-poi-cinema",
                    ["railway", "bus"], "gm-poi-rail",
                    ["library", "books"], "gm-poi-library",
                    ["fuel"], "gm-poi-fuel",
                    ["restaurant", "fast_food", "food_court"], "gm-poi-food",
                    ["cafe", "bar", "beer", "ice_cream"], "gm-poi-cafe",
                    ["shop", "grocery", "clothing_store", "jewelry", "convenience"], "gm-poi-shop",
                    ["hospital", "pharmacy", "doctors", "dentist"], "gm-poi-health",
                    ["school", "college", "university", "kindergarten"], "gm-poi-school",
                    ["parking", "bicycle_parking"], "gm-poi-parking",
                    ["stadium", "sports", "pitch"], "gm-poi-sport",
                    "gm-poi-default",
                ],
                "icon-size": 0.5,
                "text-field": NAME, "text-font": BOLD, "text-size": 10.5,
                "text-transform": p["transform"], "text-anchor": "top", "text-offset": [0, 1.1],
                "text-max-width": 8, "text-optional": True,
            },
            "paint": {"text-color": p["label"], "text-halo-color": p["halo"], "text-halo-width": 1.2},
        },
        {
            "id": "place-minor", "type": "symbol", "source": "openmaptiles", "source-layer": "place",
            "filter": cls("village", "hamlet", "suburb", "quarter", "neighbourhood"),
            "layout": {"text-field": NAME, "text-font": BOLD, "text-transform": p["transform"],
                       "text-size": interp([(10, 10), (15, 13)]), "text-max-width": 8},
            "paint": {"text-color": p["label"], "text-halo-color": p["halo"], "text-halo-width": 1.4},
        },
        {
            "id": "place-town", "type": "symbol", "source": "openmaptiles", "source-layer": "place",
            "filter": cls("town"),
            "layout": {"text-field": NAME, "text-font": BOLD, "text-transform": p["transform"],
                       "text-size": interp([(8, 11), (14, 16)]), "text-max-width": 8},
            "paint": {"text-color": p["label"], "text-halo-color": p["halo"], "text-halo-width": 1.5},
        },
        {
            "id": "place-city", "type": "symbol", "source": "openmaptiles", "source-layer": "place",
            "filter": cls("city"),
            "layout": {"text-field": NAME, "text-font": BOLD, "text-transform": p["transform"],
                       "text-size": interp([(4, 11), (10, 18)]), "text-max-width": 8},
            "paint": {"text-color": p["label"], "text-halo-color": p["halo"], "text-halo-width": 1.6},
        },
        {
            "id": "place-country", "type": "symbol", "source": "openmaptiles", "source-layer": "place",
            "filter": cls("country"), "maxzoom": 9,
            "layout": {"text-field": NAME_EN, "text-font": BOLD, "text-transform": p["transform"],
                       "text-size": interp([(2, 10), (6, 16)]), "text-max-width": 7},
            "paint": {"text-color": p["label"], "text-halo-color": p["halo"], "text-halo-width": 1.6},
        },
    ]
    return {
        "version": 8,
        "name": "GassMaps " + tid,
        "sources": {"openmaptiles": SOURCE},
        "glyphs": GLYPHS,
        "layers": layers,
    }


def globe_style(tid, p):
    """Stile leggero usato per generare la texture del globo (snapshot a zoom 2)."""
    layers = [
        {"id": "background", "type": "background", "paint": {"background-color": p["land"]}},
        {"id": "landcover-ice", "type": "fill", "source": "openmaptiles", "source-layer": "landcover",
         "filter": cls("ice"), "paint": {"fill-color": p["ice"]}},
        {"id": "landcover-sand", "type": "fill", "source": "openmaptiles", "source-layer": "landcover",
         "filter": cls("sand"), "paint": {"fill-color": p["sand"]}},
        {"id": "landcover-wood", "type": "fill", "source": "openmaptiles", "source-layer": "landcover",
         "filter": cls("wood", "forest"), "paint": {"fill-color": p["wood"], "fill-opacity": 0.8}},
        {"id": "water", "type": "fill", "source": "openmaptiles", "source-layer": "water",
         "paint": {"fill-color": p["water"]}},
        {"id": "boundary-country", "type": "line", "source": "openmaptiles", "source-layer": "boundary",
         "filter": ["all", ["==", ["get", "admin_level"], 2], ["!=", ["get", "maritime"], 1]],
         "paint": {"line-color": p["boundary"], "line-opacity": 0.55, "line-width": 0.8}},
        {"id": "road-motorway", "type": "line", "source": "openmaptiles", "source-layer": "transportation",
         "filter": cls("motorway", "trunk"),
         "paint": {"line-color": p["motor"], "line-opacity": 0.35, "line-width": 0.5}},
        {"id": "place-city", "type": "symbol", "source": "openmaptiles", "source-layer": "place",
         "filter": ["all", cls("city"), ["<=", ["to-number", ["get", "rank"], 10], 4]],
         "layout": {"text-field": NAME_EN, "text-font": BOLD, "text-size": 8,
                    "text-transform": p["transform"], "text-anchor": "left", "text-offset": [0.5, 0],
                    "icon-image": "gm-dot", "icon-size": 0.5},
         "paint": {"text-color": p["label"], "text-halo-color": p["halo"], "text-halo-width": 1}},
        {"id": "place-country", "type": "symbol", "source": "openmaptiles", "source-layer": "place",
         "filter": cls("country"),
         "layout": {"text-field": NAME_EN, "text-font": BOLD, "text-size": 9,
                    "text-transform": p["transform"], "text-max-width": 6},
         "paint": {"text-color": p["label"], "text-halo-color": p["halo"], "text-halo-width": 1.2}},
    ]
    # le etichette del globo sono disegnate in 3D dall'app (sempre rivolte verso lo schermo)
    layers = [l for l in layers if l["type"] != "symbol"]
    return {"version": 8, "name": "GassMaps globe " + tid, "sources": {"openmaptiles": SOURCE},
            "glyphs": GLYPHS, "layers": layers}


def main():
    os.makedirs(OUT, exist_ok=True)
    for tid, p in THEMES.items():
        with open(os.path.join(OUT, f"{tid}.json"), "w") as f:
            json.dump(map_style(tid, p), f, indent=1)
        with open(os.path.join(OUT, f"{tid}_globe.json"), "w") as f:
            json.dump(globe_style(tid, p), f, indent=1)
    print("Stili generati in", OUT)


if __name__ == "__main__":
    main()
