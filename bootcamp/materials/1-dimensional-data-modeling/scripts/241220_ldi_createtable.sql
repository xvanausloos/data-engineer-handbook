SELECT * FROM public.player_seasons;

CREATE TYPE season_stats AS(
	season INTEGER,
	gp INTEGER,
	pts REAL, 
	reb REAL,
	ast REAL
)

CREATE TABLE players(
	player_name TEXT,
	height TEXT,
	college TEXT,
	country TEXT,
	draft_year 	TEXT,
	draft_round TEXT,
	seasons_stas season_stats[],
	current_season INTEGER,
	PRIMARY KEY(player_name, current_season)
)



