#!/usr/bin/env zsh

set -euo pipefail

# NOTE make sure you `export HEX_DIR=/path/to/target/dir` before running this
# TODO handle hard-coded dependencies
# - expects a local postgres database `broadband` => make this an env var
# - expects a table `us_states_hexagons_deduped` => commit the sql to make this

# export all - gpkg
ogr2ogr \
  $HEX_DIR/gpkg/hex_res_8_us_all.gpkg \
  PG:"dbname=broadband" \
  -nln "hex_res_8_us_all" \
  -progress \
  -sql "select id, state_codes, state_fips, resolution, geom from us_states_hexagons_deduped"

# export all - shp
ogr2ogr \
  $HEX_DIR/shp/hex_res_8_us_all.shp.zip \
  PG:"dbname=broadband" \
  -nln "hx8_us_all" \
  -progress \
  -sql "select id, state_codes as st_codes, state_fips as st_fips, resolution as res, geom from us_states_hexagons_deduped"

# export state by state
while read state_fips_line; do
  parts=(${(s/,/)state_fips_line})
  state_fips=$parts[1]
  state_code_upper=$parts[2]
  state_code_lower=${state_code_upper:l}

  # export gpkg
  ogr2ogr \
    $HEX_DIR/gpkg/hex_res_8_us_${state_fips}_${state_code_lower}.gpkg \
    PG:"dbname=broadband" \
    -nln hex_res_8_us_${state_fips}_${state_code_lower} \
    -progress \
    -sql "select id, state_codes, state_fips, resolution, geom from us_states_hexagons_deduped where state_codes ~ '$state_code_upper'"
  
  # export shp
  ogr2ogr \
    $HEX_DIR/shp/hex_res_8_us_${state_fips}_${state_code_lower}.shp.zip \
    PG:"dbname=broadband" \
    -nln hx8_us_${state_code_lower} \
    -progress \
    -sql "select id, state_codes as st_codes, state_fips as st_fips, resolution as res, geom from us_states_hexagons_deduped where state_codes ~ '$state_code_upper'"
done < state_fips.txt
