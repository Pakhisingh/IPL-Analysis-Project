-- Top 10 batsmen based on past 3 years total runs scored

SELECT batsmanName, SUM(runs) AS total_runs
FROM fact_bating_summary
GROUP BY batsmanName
ORDER BY total_runs DESC
LIMIT 10;

-------------------------------------------------------------------------------------------

-- Top 10 batsmen based on past 3 years batting average. (min 60 balls faced in each season)

WITH s AS (
  SELECT batsmanName, 
         EXTRACT(YEAR FROM STR_TO_DATE(d.matchDate, '%b %d, %Y')) AS yr,
         SUM(runs) AS r, 
         SUM(balls) AS b,
         COUNT(CASE WHEN `out/not_out` = 'out' THEN 1 END) AS o
  FROM fact_bating_summary f
  JOIN dim_match_summary d ON f.match_id = d.match_id
  WHERE EXTRACT(YEAR FROM STR_TO_DATE(d.matchDate, '%b %d, %Y')) IN (2021, 2022, 2023)
  GROUP BY batsmanName, yr
  HAVING b >= 60
)
SELECT batsmanName, 
       ROUND(SUM(r) / NULLIF(SUM(o), 0), 2) AS average
FROM s
GROUP BY batsmanName
HAVING COUNT(DISTINCT yr) = 3
ORDER BY average DESC
LIMIT 10;

-------------------------------------------------------------------------------------------

-- Top 10 Batsmen by Strike Rate (min 60 balls in each season)

WITH s AS (
  SELECT batsmanName, 
         EXTRACT(YEAR FROM STR_TO_DATE(d.matchDate, '%b %d, %Y')) AS yr,
         SUM(runs) AS r, SUM(balls) AS b
  FROM fact_bating_summary f
  JOIN dim_match_summary d ON f.match_id = d.match_id
  WHERE EXTRACT(YEAR FROM STR_TO_DATE(d.matchDate, '%b %d, %Y')) IN (2021, 2022, 2023)
  GROUP BY batsmanName, yr
  HAVING b >= 60
)
SELECT batsmanName, ROUND(SUM(r)*100.0 / SUM(b), 2) AS SR
FROM s
GROUP BY batsmanName
HAVING COUNT(DISTINCT yr) = 3
ORDER BY SR DESC
LIMIT 10;

-------------------------------------------------------------------------------------------

-- Top 10 bowlers based on past 3 years total wickets taken.

SELECT bowlerName, SUM(wickets) AS total_wickets
FROM fact_bowling_summary f
JOIN dim_match_summary d ON f.match_id = d.match_id
WHERE EXTRACT(YEAR FROM STR_TO_DATE(d.matchDate, '%b %d, %Y')) IN (2021, 2022, 2023)
GROUP BY bowlerName
ORDER BY total_wickets DESC
LIMIT 10;

-------------------------------------------------------------------------------------------

--- Top 10 bowlers based on past 3 years bowling average.

WITH s AS (
  SELECT bowlerName,
         EXTRACT(YEAR FROM STR_TO_DATE(d.matchDate, '%b %d, %Y')) AS yr,
         SUM(runs) AS r, SUM(overs)*6 AS balls, SUM(wickets) AS w
  FROM fact_bowling_summary f
  JOIN dim_match_summary d ON f.match_id = d.match_id
  WHERE EXTRACT(YEAR FROM STR_TO_DATE(d.matchDate, '%b %d, %Y')) IN (2021, 2022, 2023)
  GROUP BY bowlerName, yr
  HAVING balls >= 60
)
SELECT bowlerName, ROUND(SUM(r) / NULLIF(SUM(w), 0), 2) AS avg
FROM s
GROUP BY bowlerName
HAVING COUNT(DISTINCT yr) = 3
ORDER BY avg
LIMIT 10;

-------------------------------------------------------------------------------------------

-- Top 10 Bowlers by Economy 

SELECT bowlerName, ROUND(AVG(avg_economy), 2) AS economy
FROM (
  SELECT bowlerName,
         EXTRACT(YEAR FROM STR_TO_DATE(dms.matchDate, '%b %d, %Y')) AS Season,
         SUM(overs)*6 AS balls,
         AVG(economy) AS avg_economy
  FROM fact_bowling_summary b
  JOIN dim_match_summary dms ON dms.match_id = b.match_id
  WHERE EXTRACT(YEAR FROM STR_TO_DATE(dms.matchDate, '%b %d, %Y')) IN (2021, 2022, 2023)
  GROUP BY bowlerName, Season
  HAVING balls >= 60
) t1
GROUP BY bowlerName
HAVING COUNT(DISTINCT Season) = 3
ORDER BY economy asc
LIMIT 10;

-------------------------------------------------------------------------------------------

-- Top 5 batsmen based on past 3 years boundary % 

SELECT batsmanName,
       ROUND((SUM(`4s`) + SUM(`6s`)) * 100.0 / SUM(balls), 2) AS boundary_pct
FROM fact_bating_summary f
JOIN dim_match_summary d ON f.match_id = d.match_id
WHERE EXTRACT(YEAR FROM STR_TO_DATE(d.matchDate, '%b %d, %Y')) IN (2021, 2022, 2023)
GROUP BY batsmanName
HAVING SUM(balls) > 60
ORDER BY boundary_pct DESC
LIMIT 5;

-------------------------------------------------------------------------------------------

-- Top 5 bowlers based on past 3 years dot ball %.

SELECT bowlerName,
       ROUND(SUM(`0s`) * 100.0 / (SUM(overs) * 6), 2) AS dot_pct
FROM fact_bowling_summary f
JOIN dim_match_summary d ON f.match_id = d.match_id
WHERE EXTRACT(YEAR FROM STR_TO_DATE(d.matchDate, '%b %d, %Y')) IN (2021, 2022, 2023)
GROUP BY bowlerName
HAVING SUM(overs)*6 >= 180
ORDER BY dot_pct DESC
LIMIT 5;

-------------------------------------------------------------------------------------------

-- Top 4 Teams by Winning % 

SELECT team, 
       COUNT(*) AS matches_played,
       SUM(CASE WHEN team = winner THEN 1 ELSE 0 END) AS matches_won,
       ROUND(SUM(team = winner) * 100.0 / COUNT(*), 2) AS win_pct
FROM (
  SELECT team1 AS team, winner, matchDate FROM dim_match_summary
  UNION ALL
  SELECT team2, winner, matchDate FROM dim_match_summary
) AS all_matches
WHERE EXTRACT(YEAR FROM STR_TO_DATE(matchDate, '%b %d, %Y')) IN (2021, 2022, 2023)
GROUP BY team
ORDER BY win_pct DESC
LIMIT 4;

-------------------------------------------------------------------------------------------

--- Top 2 teams with the highest number of wins achieved by chasing targets over the past 3 years.

SELECT winner, COUNT(*) AS chase_wins
FROM dim_match_summary
WHERE EXTRACT(YEAR FROM STR_TO_DATE(matchDate, '%b %d, %Y')) IN (2021, 2022, 2023)
  AND margin LIKE '%wickets'
GROUP BY winner
ORDER BY chase_wins DESC
LIMIT 2;

-------------------------------------------------------------------------------------------

-- Predictions for 2024 IPL Season

--- Orange Cap Holder (Batsman)

SELECT batsmanName, team, SUM(runs) AS total_runs
FROM fact_bating_summary AS fb
JOIN dim_players AS dp ON fb.batsmanName = dp.name
GROUP BY batsmanName, team
ORDER BY total_runs DESC
LIMIT 1;

--- Purple Cap Holder (Bowler)

SELECT bowlerName, team, SUM(wickets) AS total_wickets
FROM fact_bowling_summary AS fb
JOIN dim_players AS dp ON fb.bowlerName = dp.name
GROUP BY bowlerName, team
ORDER BY total_wickets DESC
LIMIT 1;

--- Top 4 Qualifying Teams in 2024 season

SELECT winner, COUNT(winner) AS total_wins
FROM dim_match_summary
GROUP BY winner
ORDER BY total_wins DESC
LIMIT 4;

--- Winner & Runner-up

SELECT winner, COUNT(winner) AS total_wins
FROM dim_match_summary
GROUP BY winner
ORDER BY total_wins DESC
LIMIT 2;

-------------------------------------------------------------------------------------------

-- My Picks

--- Top 11 Players

WITH my_cte AS (
    (SELECT batsmanName AS player_name, SUM(runs) AS runs_scored, COUNT(*) AS matches_played, playingRole
     FROM fact_bating_summary fb
     JOIN dim_players dp ON dp.name = fb.batsmanName
     WHERE playingRole = 'Opening Batter'
     GROUP BY 1, 4
     ORDER BY 2 DESC
     LIMIT 2)
    UNION ALL
    (SELECT batsmanName AS player_name, SUM(runs) AS runs_scored, COUNT(*) AS matches_played, playingRole
     FROM fact_bating_summary fb
     JOIN dim_players dp ON dp.name = fb.batsmanName
     WHERE playingRole = 'Top order Batter'
     GROUP BY 1, 4
     ORDER BY 2 DESC
     LIMIT 1)
    UNION ALL
    (SELECT batsmanName AS player_name, SUM(runs) AS runs_scored, COUNT(*) AS matches_played, playingRole
     FROM fact_bating_summary fb
     JOIN dim_players dp ON dp.name = fb.batsmanName
     WHERE playingRole = 'Middle order Batter'
     GROUP BY 1, 4
     ORDER BY 2 DESC
     LIMIT 1)
    UNION ALL
    (SELECT batsmanName AS player_name, SUM(runs) AS runs_scored, COUNT(*) AS matches_played, playingRole
     FROM fact_bating_summary fb
     JOIN dim_players dp ON dp.name = fb.batsmanName
     WHERE playingRole = 'Wicketkeeper Batter'
     GROUP BY 1, 4
     ORDER BY 2 DESC
     LIMIT 1)
    UNION ALL
    (SELECT bowlerName AS player_name, SUM(wickets) AS total_wickets, COUNT(*) AS matches_played, playingRole
     FROM fact_bowling_summary fb
     JOIN dim_players dp ON dp.name = fb.bowlerName
     WHERE playingRole = 'Bowling Allrounder'
     GROUP BY 1, 4
     ORDER BY 2 DESC
     LIMIT 2)
    UNION ALL
    (SELECT bowlerName AS player_name, SUM(wickets) AS total_wickets, COUNT(*) AS matches_played, playingRole
     FROM fact_bowling_summary fb
     JOIN dim_players dp ON dp.name = fb.bowlerName
     WHERE playingRole = 'Bowler'
     GROUP BY 1, 4
     ORDER BY 2 DESC
     LIMIT 4)
)
SELECT player_name, playingRole FROM my_cte;

-------------------------------------------------------------------------------------------

--- Top 3 Allrounders

WITH bowling AS (
    SELECT 
        bowlerName AS name, 
        SUM(wickets) AS total_wickets
    FROM fact_bowling_summary fb
    JOIN dim_players dm ON dm.name = fb.bowlerName
    WHERE playingRole IN ('Allrounder', 'Bowling Allrounder', 'Batting Allrounder')
    GROUP BY 1
), 
batsman AS (
    SELECT 
        batsmanName AS name, 
        SUM(runs) AS total_runs
    FROM fact_bating_summary fb
    JOIN dim_players dm ON dm.name = fb.batsmanName
    WHERE playingRole IN ('Allrounder', 'Bowling Allrounder', 'Batting Allrounder')
    GROUP BY 1
) 
SELECT 
    batsman.name, 
    total_wickets, 
    total_runs 
FROM batsman 
JOIN bowling ON bowling.name = batsman.name
WHERE total_wickets >= 25 AND total_runs >= 500
ORDER BY total_runs DESC
LIMIT 4;
