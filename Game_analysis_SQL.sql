select * from Game..[Player_details (1)]
select * from Game..[level_details2 (1)]

--1. Extract `P_ID`, `Dev_ID`, `PName`, and `Difficulty_level` of all players at Level 0.
select a.P_ID , a.Dev_ID , b.PName ,a.Difficulty
from Game..[level_details2 (1)] a
join Game..[Player_details (1)] b on a.P_ID=b.P_ID
where a.Level=0;

--2. Finds the total number of stages crossed at each difficulty level for Level 2 with players.
select sum(Stages_crossed ) as [total number of stages], Difficulty  
from Game..[level_details2 (1)]
where Level=2
group by Difficulty 

--3. Find `Level1_code`wise average `Kill_Count` where `lives_earned` is 2, and at least 3 stages are crossed. using `zm_series` devices. Arrange the result in decreasing order of the total number of stages crossed.

select b.L1_Code, avg(a.Kill_Count) as [average kill count], sum(a.Stages_crossed) as [total number of stages]
from Game..[level_details2 (1)] a
join Game..[Player_details (1)] b on a.P_ID = b.P_ID
where a.Stages_crossed >= 3 and a.Lives_Earned = 2 and a.Dev_ID like 'zm%'
group by b.L1_Code
order by [total number of stages] desc

--4. Extract `P_ID` and the total number of unique dates for those players who have played games on multiple days.
select b.P_ID, count(distinct a.TimeStamp) as [unique_days]
from Game..[level_details2 (1)] a
join Game..[Player_details (1)] b on a.P_ID = b.P_ID
group by b.P_ID
having count(distinct a.TimeStamp) >= 2;

--5. Find `P_ID` and levelwise sum of `kill_counts` where `kill_count` is greater than the average kill count for Medium difficulty.
--//need to recheck it again 
-- Subquery to calculate the average Kill_Count for Medium difficulty
WITH MediumAvg AS (
    SELECT AVG(Kill_Count) AS AvgKillCount
    FROM Game..[level_details2 (1)]
    WHERE Difficulty = 'Medium'
)

-- Main query to filter based on the calculated average
SELECT P_ID, SUM(Kill_Count) AS TotalKillCount, Difficulty , AVG(Kill_Count) AS AvgKillCount
FROM Game..[level_details2 (1)]
WHERE Difficulty = 'Medium' and
Kill_Count > (SELECT AvgKillCount FROM MediumAvg)
GROUP BY P_ID, Difficulty
HAVING SUM(Kill_Count) > (SELECT AvgKillCount FROM MediumAvg);


--6. Find `Level` and its corresponding `Level_code`wise sum of lives earned, excluding Level 0. Arrange in ascending order of level.
select a.Level , b.L1_Code , b.L2_Code ,sum(a.Lives_Earned) as LivesEarned_Sum
from Game..[level_details2 (1)] a
join Game..[Player_details (1)] b on a.P_ID = b.P_ID
where a.Level !=0
group by b.L1_Code , b.L2_Code ,a.Level
order by a.Level asc 

--7. Find the top 3 scores based on each `Dev_ID` and rank them in increasing order using `Row_Number`. Display the difficulty as well.
select top 3 (score), 
Dev_ID , Difficulty
from Game..[level_details2 (1)] 
order by column1 asc

-----------------------------------------------------------------------------------------------------------------------------
WITH RankedScores AS (
    SELECT 
        Dev_ID, 
        Difficulty, 
        score, 
        ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY score ASC) AS RowNum
    FROM Game..[level_details2 (1)]
)
SELECT top 3 (Score)
    Dev_ID, 
    Difficulty, 
    
    RowNum
FROM RankedScores
WHERE RowNum <= 3
ORDER BY Dev_ID, RowNum;


--8. Find the `first_login` datetime for each device ID.
select min(TimeStamp), Dev_ID 
from Game..[level_details2 (1)] 
group by Dev_ID 

--9. Find the top 5 scores based on each difficulty level and rank them in increasing order using `Rank`. Display `Dev_ID` as well.
select top 5 (score), 
Dev_ID , Difficulty
from Game..[level_details2 (1)] 
order by column1 asc

-----------------------------------------------------------------------------------------------------------------------------------
WITH RankedScores AS (
    SELECT 
        Dev_ID, 
        Difficulty, 
        score, 
        RANK() OVER (PARTITION BY Difficulty ORDER BY score ASC) AS Rank
    FROM Game..[level_details2 (1)]
)
SELECT top 5 (score),
    Dev_ID, 
    Difficulty, 
     
    Rank
FROM RankedScores
WHERE Rank <= 5
ORDER BY Difficulty, Rank;

--10. Find the device ID that is first logged in (based on `start_datetime`) for each player (`P_ID`). Output should contain player ID, device ID, and first login datetime.
select Dev_ID ,P_ID,min(TimeStamp)
from Game..[level_details2 (1)] 
group by  Dev_ID ,P_ID;

---------------------------------------------------------------------------------------------------------------------------------
WITH RankedLogins AS (
    SELECT 
        Dev_ID,
        P_ID,
        TimeStamp,
        ROW_NUMBER() OVER (PARTITION BY P_ID ORDER BY TimeStamp ASC) AS RowNum
    FROM Game..[level_details2 (1)]
)
SELECT 
    Dev_ID,
    P_ID,
    TimeStamp AS First_Login_Datetime
FROM RankedLogins
WHERE RowNum = 1;

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
--11. For each player and date, determine how many `kill_counts` were played by the player so far.
--a) Using window functions
SELECT 
    P_ID,
    CONVERT(date,TimeStamp) AS Play_Date,
    SUM(kill_count) OVER (PARTITION BY P_ID ORDER BY TimeStamp) AS Total_Kill_Count
FROM Game..[level_details2 (1)]

--b) Without window functions
SELECT 
    ld.P_ID,
    CONVERT(date, ld.TimeStamp) AS Play_Date,
    (
        SELECT SUM(ld_inner.kill_count) 
        from Game..[level_details2 (1)] ld_inner 
        WHERE ld_inner.P_ID = ld.P_ID 
        AND CONVERT(date, ld_inner.TimeStamp) <= CONVERT(date, ld.TimeStamp)
    ) AS Total_Kill_Count
FROM Game..[level_details2 (1)] ld;
--12. Find the cumulative sum of stages crossed over `start_datetime` for each `P_ID`, excluding the most recent `start_datetime`.
--without excluding the most recent `start_datetime`.
SELECT 
    P_ID,
    CONVERT(date, TimeStamp) AS Play_Date,
    SUM(Stages_crossed) OVER (PARTITION BY P_ID ORDER BY TimeStamp ROWS UNBOUNDED PRECEDING) AS Total_Stages_crossed
FROM Game..[level_details2 (1)]
ORDER BY P_ID, Play_Date;
--with excluding the most recent `start_datetime`.
WITH CTE AS (
    SELECT 
        P_ID,
        TimeStamp,
        Stages_crossed,
        ROW_NUMBER() OVER (PARTITION BY P_ID ORDER BY TimeStamp DESC) AS rn
    FROM Game..[level_details2 (1)]
)
SELECT 
    P_ID,
    TimeStamp,
    SUM(Stages_crossed) OVER (PARTITION BY P_ID ORDER BY TimeStamp ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS Cumulative_Stages_Excluding_Most_Recent
FROM CTE
WHERE rn > 1
ORDER BY P_ID, TimeStamp;


--13. Extract the top 3 highest sums of scores for each `Dev_ID` and the corresponding `P_ID`
WITH Scores AS (
    SELECT 
        Dev_ID,
        P_ID,
        SUM(Stages_crossed) AS Total_stages
    FROM Game..[level_details2 (1)]
    GROUP BY Dev_ID, P_ID
),
RankedScores AS (
    SELECT 
        Dev_ID,
        P_ID,
        Total_stages,
        ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY Total_stages DESC) AS rn
    FROM Scores
)
SELECT 
    Dev_ID,
    P_ID,
    Total_stages
FROM RankedScores
WHERE rn <= 3
ORDER BY Dev_ID, rn;

--14. Find players who scored more than 50% of the average score, scored by the sum of scores for each `P_ID`.
WITH PlayerScores AS (
    SELECT 
        P_ID,
        SUM(Stages_crossed) AS Total_Score
    FROM Game..[level_details2 (1)]
    GROUP BY P_ID
),
AverageScore AS (
    SELECT 
        AVG(Total_Score) AS Avg_Score
    FROM PlayerScores
)
SELECT 
    P_ID,
    Total_Score
FROM PlayerScores
WHERE Total_Score > 0.5 * (SELECT Avg_Score FROM AverageScore);

--15. Create a stored procedure to find the top `n` `headshots_count` based on each `Dev_ID` and rank them in increasing order using `Row_Number`. Display the difficulty as well.
-------- //PlayerScores procedure//--------------
CREATE PROCEDURE GetTopNHeadshots
    @n INT
AS
BEGIN
    WITH RankedHeadshots AS (
        SELECT 
            Dev_ID,
            P_ID,
            headshots_count,
            difficulty,
            ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY headshots_count ASC) AS rn
        FROM Game..[level_details2 (1)]
    )
    SELECT 
        Dev_ID,
        P_ID,
        headshots_count,
        difficulty,
        rn AS Rank
    FROM RankedHeadshots
    WHERE rn <= @n
    ORDER BY Dev_ID, Rank;
END;

----//Execute a Stored Procedure//-----
EXEC GetTopNHeadshots @n = 2;  -- Replace 2 with the desired value of n
