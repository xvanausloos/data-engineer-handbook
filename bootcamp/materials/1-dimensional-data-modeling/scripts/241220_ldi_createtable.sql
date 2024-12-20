SELECT * FROM public.player_seasons;

CREATE TYPE season_stats AS(
	season INTEGER,
	gp INTEGER,
	pts REAL, 
	reb REAL,
	ast REAL
)


-- drop table players;

 CREATE TYPE season_stats AS (
                         season Integer,
                         pts REAL,
                         ast REAL,
                         reb REAL,
                         weight INTEGER
                       );
                      
 CREATE TYPE scoring_class AS
     ENUM ('bad', 'average', 'good', 'star');


 
-- drop table players ;
    
-- truncate table players
    
 CREATE TABLE players (
    player_name TEXT,
    height TEXT,
    college TEXT,
    country TEXT,
    draft_year TEXT,
    draft_round TEXT,
    draft_number TEXT,
    seasons season_stats[],
    scorer_class scoring_class,
    years_since_last_active INTEGER,
    is_active BOOLEAN,
    current_season INTEGER,
    PRIMARY KEY (player_name, current_season)
);

-- pipeline query


INSERT INTO players (
    player_name,
    height,
    college,
    country,
    draft_year,
    draft_round,
    draft_number,
    seasons,
    scorer_class,
    years_since_last_active,
    is_active,
    current_season
)
WITH years AS (
    SELECT *
    FROM GENERATE_SERIES(1996, 2022) AS season
), p AS (
    SELECT
        player_name,
        MIN(season) AS first_season
    FROM player_seasons
    GROUP BY player_name
), players_and_seasons AS (
    SELECT *
    FROM p
    JOIN years y
        ON p.first_season <= y.season
), windowed AS (
    SELECT
        pas.player_name,
        pas.season,
        ARRAY_REMOVE(
            ARRAY_AGG(
                CASE
                    WHEN ps.season IS NOT NULL
                        THEN ROW(
                            ps.season,
                            ps.gp,
                            ps.pts,
                            ps.reb,
                            ps.ast
                        )::season_stats
                END)
            OVER (PARTITION BY pas.player_name ORDER BY COALESCE(pas.season, ps.season)),
            NULL
        ) AS seasons
    FROM players_and_seasons pas
    LEFT JOIN player_seasons ps
        ON pas.player_name = ps.player_name
        AND pas.season = ps.season
    ORDER BY pas.player_name, pas.season
), static AS (
    SELECT
        player_name,
        MAX(height) AS height,
        MAX(college) AS college,
        MAX(country) AS country,
        MAX(draft_year) AS draft_year,
        MAX(draft_round) AS draft_round,
        MAX(draft_number) AS draft_number
    FROM player_seasons
    GROUP BY player_name
)
SELECT
    w.player_name,
    s.height,
    s.college,
    s.country,
    s.draft_year,
    s.draft_round,
    s.draft_number,
    seasons AS season_stats,
    CASE
        WHEN (seasons[CARDINALITY(seasons)]::season_stats).pts > 20 THEN 'star'
        WHEN (seasons[CARDINALITY(seasons)]::season_stats).pts > 15 THEN 'good'
        WHEN (seasons[CARDINALITY(seasons)]::season_stats).pts > 10 THEN 'average'
        ELSE 'bad'
    END::scoring_class AS scorer_class,
    w.season - (seasons[CARDINALITY(seasons)]::season_stats).season AS years_since_last_active,
    ((seasons[CARDINALITY(seasons)]::season_stats).season = w.season)::BOOLEAN AS is_active,
    w.season AS current_season
FROM windowed w
JOIN static s
    ON w.player_name = s.player_name;


ALTER TABLE players
RENAME COLUMN scorer_class TO scoring_class;
