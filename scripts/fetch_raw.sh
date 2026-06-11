#!/usr/bin/env bash
# Download all raw input files before R processing.
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW_DIR="$ROOT_DIR/data/raw"
AGRAR_DIR="$RAW_DIR/agrarforschung"
mkdir -p "$RAW_DIR" "$AGRAR_DIR"

curl_download() {
  local url="$1"
  local output="$2"
  local tmp="${output}.tmp"

  echo "Downloading $url -> ${output#$ROOT_DIR/}"
  curl \
    --fail \
    --location \
    --silent \
    --show-error \
    --retry 3 \
    --retry-delay 5 \
    --retry-all-errors \
    --connect-timeout 30 \
    --max-time 300 \
    --user-agent "holzpreise.at-data-fetch" \
    --output "$tmp" \
    "$url"

  test -s "$tmp"
  mv "$tmp" "$output"
}

curl_download_with_fallback() {
  local primary_url="$1"
  local fallback_url="$2"
  local output="$3"

  if ! curl_download "$primary_url" "$output"; then
    echo "Primary download failed, trying fallback: $fallback_url"
    curl_download "$fallback_url" "$output"
  fi
}

# Tirol Walddatenbank / Land Tirol ------------------------------------------------
curl_download "https://www.tirol.gv.at/umwelt/wald/holzmarkt/holzpreise/" "$RAW_DIR/tirol_holzpreise_info.html"
curl_download "https://wdb.tirol.gv.at/public/holzPreisBerichtParams.xhtml" "$RAW_DIR/tirol_wdb_holzpreistabelle_params.html"
curl_download "https://wdb.tirol.gv.at/public/rupiQuartal.xhtml" "$RAW_DIR/tirol_wdb_rupi_quartal.html"
curl_download "https://wdb.tirol.gv.at/public/rupiMonat.xhtml" "$RAW_DIR/tirol_wdb_rupi_monat.html"
curl_download "https://wdb.tirol.gv.at/public/bhiQuartal.xhtml" "$RAW_DIR/tirol_wdb_bhi_quartal.html"
curl_download "https://wdb.tirol.gv.at/public/bhiJahr.xhtml" "$RAW_DIR/tirol_wdb_bhi_jahr.html"

# Statistik Austria via Bunny Edge proxy first ------------------------------------
curl_download_with_fallback "https://www.holzpreise.at/_data/statistik/vpi76.csv" "https://data.statistik.gv.at/data/OGD_vpi76_VPI_1976_1.csv" "$RAW_DIR/statistik_austria_vpi_1976.csv"
curl_download_with_fallback "https://www.holzpreise.at/_data/statistik/vpi20-coicop18.csv" "https://data.statistik.gv.at/data/OGD_vpi20c18_VPI_2020COICOP18_1.csv" "$RAW_DIR/statistik_austria_vpi_2020_coicop18.csv"
curl_download_with_fallback "https://www.holzpreise.at/_data/statistik/epi2021-oecpa.csv" "https://data.statistik.gv.at/data/OGD_epi2021cpa15_EPI_2021_OECPA_1.csv" "$RAW_DIR/statistik_austria_epi_2021_oecpa.csv"
curl_download_with_fallback "https://www.holzpreise.at/_data/statistik/ghpi2020.csv" "https://data.statistik.gv.at/data/OGD_pregpi003_GHPI_20_1.csv" "$RAW_DIR/statistik_austria_ghpi_2020.csv"

# preise.agrarforschung.at API -----------------------------------------------------
content_ids=(
  saegeholz_monatl
  industrierundholz_monatl
  brennholz_monatl
  energieholzkodex
  pellets
  holzprodukte
  schnittholz_chicago
  schnittholz_schwedische_kiefer
  diesel_woechentl
  saegerundholz_bgld
  saegerundholz_ktn
  saegerundholz_noe
  saegerundholz_ooe
  saegerundholz_sbg
  saegerundholz_stmk
  saegerundholz_t
  saegerundholz_vbg
  industrierundholz_bgld
  industrierundholz_ktn
  industrierundholz_noe
  industrierundholz_ooe
  industrierundholz_sbg
  industrierundholz_stmk
  industrierundholz_t
  industrierundholz_vbg
  brennholz_bgld
  brennholz_ktn
  brennholz_noe
  brennholz_ooe
  brennholz_sbg
  brennholz_stmk
  brennholz_t
  brennholz_vbg
)

for content_id in "${content_ids[@]}"; do
  curl_download "https://preise.agrarforschung.at/api/getcontent?contentId=${content_id}" "$AGRAR_DIR/${content_id}.json"
done

echo "Raw downloads complete."
