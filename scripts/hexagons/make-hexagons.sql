create table us_hexagons as
with hexagon_ids as ( 
	select
		h3_polygon_to_cells(
			geom,
			8
		) as id
  -- this table consisted of hand-drawn bounding boxes around clustered
  -- land masses (e.g. the hawaiian islands were one "envelope")
  -- TODO a buffer would probably work as well, i just wasn't sure what the 
  -- right distance to make sure all land was covered by a hexagon.
	from us_states_and_territories_envelopes
)
select
	id,
	h3_cell_to_boundary_geometry(id) as geom
from hexagon_ids
;

create index us_hexagons_geom_idx on us_hexagons using gist (geom);

create table us_hexagons_xsect_states as
select
	h.id,
	s.fips,
	s.state,
	h.geom
from us_hexagons h
join us_states_and_territories s
	on st_intersects(h.geom, s.geom)
;

-- the hexes above are many-to-one with states so there will be dupes where a 
-- hex covers more than one state; this creates a unique set
create table us_hexagons_deduped as
select
	id,
	string_agg(state_code, ',' order by state_code) as state_codes,
	string_agg(state_fips, ',' order by state_fips) as state_fips,
	8 as resolution,
	geom
from us_hexagons
group by id, geom
;

create index us_hexagons_geom_idx on us_hexagons using gist (geom);
