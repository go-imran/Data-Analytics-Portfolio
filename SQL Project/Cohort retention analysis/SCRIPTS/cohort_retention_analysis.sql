/*====================================================================================================
================================ Retention Analysis ===================================================
analysis steps :
				1. finding the first subscription/term date for each id
                2. include another two column for first date and end date
                3. including a date column from dim date table between the range start and end date for each id 
                4. then make a period column by subtracting first term date for each term and dim date table date
                5. now for each period count id 
                6. then take the first value for the first period which is supposed to be 0 and the column name is cohort size
                7. then find the percentage or retaintion (cohort size*100/first value)

*/
/*
===================================================================================================
 ====================Preparing the table for the retention analysis================================
===================================================================================================
*/
 SELECT 
    a.id_bioguide, 
    a.first_term,
    b.term_start, 
    b.term_end,
    c.date,
-- subtracting first term date for each term and dim date table date to get hte period
    COALESCE(TIMESTAMPDIFF(YEAR, a.first_term, c.date),0) AS period
FROM (
    SELECT 
        id_bioguide, 
        MIN(term_start) AS first_term
    FROM legislators_terms
    GROUP BY id_bioguide
) a
JOIN legislators_terms b 
    ON a.id_bioguide = b.id_bioguide
LEFT JOIN dim_date c 
-- retriving date from date table keeping the range between first term to term end and keep the month december 31 for all year.
    ON c.date BETWEEN b.term_start AND b.term_end
    AND c.month_name = 'December'
    AND c.day = 31
ORDER BY a.id_bioguide, c.date;


/*
============================================================================== 
====================Actrual retention analysis=================================
===============================================================================
*/

SELECT 
	period,
    first_value(COUNT( distinct id_bioguide)) OVER (ORDER BY period) AS Cohort_size,
	COUNT(distinct id_bioguide) as cohort_retained,
   ((count(id_bioguide)*100/nullif(first_value(COUNT(id_bioguide)) OVER (ORDER BY period),0))) as Retained_percentage
FROM(
 SELECT 
 id_bioguide,
 first_term,
 term_start,
 term_end,
 date,
 period
 FROM (
 
 SELECT 
    a.id_bioguide, 
    a.first_term,
    b.term_start, 
    b.term_end,
    c.date,
-- subtracting first term date for each term and dim date table date to get hte period
    COALESCE(TIMESTAMPDIFF(YEAR, a.first_term, c.date),0) AS period
FROM (
    SELECT 
        id_bioguide, 
        MIN(term_start) AS first_term
    FROM legislators_terms
    GROUP BY id_bioguide
) a
JOIN legislators_terms b 
    ON a.id_bioguide = b.id_bioguide
LEFT JOIN dim_date c 
-- retriving date from date table keeping the range between first term to term end and keep the month december 31 for all year.
    ON c.date BETWEEN b.term_start AND b.term_end
    AND c.month_name = 'December'
    AND c.day = 31
ORDER BY a.id_bioguide, c.date
) AS T) AS R
GROUP BY period
;
/*
============================================================================================================
 =============================================== Data granularity ==========================================
========== Creating the table group by year, month, centuries basis=========================================
======= Here we have done for only year.,state but we can group up the analysis based on month, century, gender, state, term_type and so on.================
============================================================================================================
*/
 SELECT 
		*
 FROM
 (
SELECT 
	year(r.first_term)as first_year,
	period,
    state,
    first_value(COUNT(distinct id_bioguide)) OVER (ORDER BY year(r.first_term),period) AS Cohort_size,
	COUNT(distinct id_bioguide) as cohort_retained,
   ((count(distinct id_bioguide)*100/nullif(first_value(COUNT(distinct id_bioguide)) OVER (ORDER BY year(r.first_term),period),0))) as Retained_percentage
FROM(
 SELECT 
 id_bioguide,
 state,
 first_term,
 term_start,
 term_end,
 date,
 period
 FROM (
 
 SELECT 
    a.id_bioguide,
    a.state,
    a.first_term,
    b.term_start, 
    b.term_end,
    c.date,
-- subtracting first term date for each term and dim date table date to get hte period
    COALESCE(TIMESTAMPDIFF(YEAR, a.first_term, c.date),0) AS period
FROM (
    SELECT 
        id_bioguide, 
        MIN(term_start) AS first_term,
        state
    FROM legislators_terms
    GROUP BY id_bioguide
) a
JOIN legislators_terms b 
    ON a.id_bioguide = b.id_bioguide
LEFT JOIN dim_date c 
-- retriving date from date table keeping the range between first term to term end and keep the month december 31 for all year.
    ON c.date BETWEEN b.term_start AND b.term_end
    AND c.month_name = 'December'
    AND c.day = 31
ORDER BY a.id_bioguide, c.date
) AS T) AS R
GROUP BY year(r.first_term),period) AS G
GROUP BY first_year,period,state,Cohort_size,Retained_percentage
;