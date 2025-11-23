-- ============================================================
-- View: vw_hr_recruitment_data_Report
-- Purpose: Creates a summarized Recruitment Report for HR.
--
-- Summary:
-- This report brings all applicant information together and calculates
-- useful scores such as education score, experience score, fit score,
-- age advantage, and an overall candidate ranking score.
--
-- It also classifies candidates into categories (Strong, Good, Weak),
-- assigns expected salary bands, and marks selected or rejected applicants.
--
-- HR Benefit:
-- Helps HR quickly identify strong candidates, compare applicants fairly,
-- and make better hiring decisions based on clear metrics.
-- ============================================================

IF OBJECT_ID('gold.vw_hr_recruitment_data_Report', 'V') IS NOT NULL
    DROP VIEW gold.vw_hr_recruitment_data_Report;
GO
CREATE VIEW gold.vw_hr_recruitment_data_Report AS
SELECT
ApplicantID,
	[Applicant Full Name],
	[Application Status],
	[Application Date],
	YEAR([Application Date]) AS [Application Year],
	MONTH([Application Date]) AS [Application Month],
	DATEDIFF(DAY,[Application Date],GETDATE()) AS [Days Since Application],
	Gender,
	[Age At Application],
	[Education Level],
	[Years Of Experience],
	[Current Job Department],
	[Education Score],
	[Experience Score],
	[Candidate Score],
	CASE
		WHEN [Age At Application] BETWEEN 25 AND 35 THEN 3
		WHEN [Age At Application] BETWEEN 36 AND 45 THEN 2
		ELSE 1
    END AS [Age Advantage Score],
	[Candidate Ranking score],
	CASE
    WHEN [Candidate Ranking score] >= 6 THEN 'Strong fit, top candidates'
    WHEN [Candidate Ranking score] >= 4 THEN 'Good candidates'
    ELSE 'Weak candidates'
	END AS [Candidate Ranking Category],
    [Expected Salary Band],
	[Is Selected Flag],
	[Is Rejected Flag]
FROM
(
SELECT
	ApplicantID,
	[Applicant Full Name],
	[Application Status],
	[Application Date],
	YEAR([Application Date]) AS [Application Year],
	MONTH([Application Date]) AS [Application Month],
	DATEDIFF(DAY,[Application Date],GETDATE()) AS [Days Since Application],
	Gender,
	[Age At Application],
	[Education Level],
	[Years Of Experience],
	[Current Job Department],
	[Education Score],
	[Experience Score],
	[Candidate Score],
	CASE
		WHEN [Age At Application] BETWEEN 25 AND 35 THEN 3
		WHEN [Age At Application] BETWEEN 36 AND 45 THEN 2
		ELSE 1
    END AS [Age Advantage Score],
	[Candidate Category],
	[Candidate Fit Score],

	(
    [Candidate Score]
    + ([Candidate Fit Score] * 0.5)
    + (	CASE
		WHEN [Age At Application] BETWEEN 25 AND 35 THEN 3
		WHEN [Age At Application] BETWEEN 36 AND 45 THEN 2
		ELSE 1
    END * 0.2)

	) AS [Candidate Ranking score],

	CASE
		WHEN [Candidate Fit Score] >= 4 THEN 'Excellent'
		WHEN [Candidate Fit Score] >= 3 THEN 'Good'
		WHEN [Candidate Fit Score] >= 2 THEN 'Average'
		ELSE 'Poor'
	END AS [Candidate Fit Category],
	CASE 
    WHEN [Desired Salary] <= 30000 THEN 'Low Range'
    WHEN [Desired Salary] BETWEEN 30000 AND 60000 THEN 'Mid Range'
    ELSE 'High Range'
	END AS [Expected Salary Band],
	[Is Selected Flag],
	[Is Rejected Flag]

FROM 
(
SELECT 
	*,
	CASE
		WHEN [Candidate Score] >= 4 THEN 'Excellent'
		WHEN [Candidate Score] >= 3 THEN 'Good'
		WHEN [Candidate Score] >= 2 THEN 'Average'
		ELSE 'Needs Improvement'
	END AS [Candidate Category],
	(
    [Candidate Score] *
    CASE 
        -- IT & Engineering
        WHEN [Current Job Department] IN (
            'IT','systems','electronics','electrical','aeronautical','engineering',
            'structural','industrial','manufacturing','product/process development',
            'technical sales','manufacturing systems','maintenance (IT)',
            'control and instrumentation','minerals','petroleum','drilling',
            'marine','automotive','civil (consulting)','civil (contracting)'
        ) THEN 1.20
        
        -- Medical & Healthcare
        WHEN [Current Job Department] IN (
            'biomedical','audiological','diagnostic','clinical','mental health',
            'physiological','speech and language','therapeutic','histocompatibility and immunogenetics',
            'clinical (histocompatibility and immunogenetics)','nutritional','forensic'
        ) THEN 1.25
        
        -- Education
        WHEN [Current Job Department] IN (
            'education','further education','adult education','secondary school',
            'primary school','early years/pre','higher education','children''s',
            'special educational needs','educational'
        ) THEN 1.10
        
        -- Creative / Media / Arts
        WHEN [Current Job Department] IN (
            'television','television/film set','broadcasting','film/video',
            'broadcasting/film/video','exhibition/display','drama','arts',
            'multimedia','fashion/clothing','graphic','interior/spatial','art',
            'magazine','magazine features','newspaper','blown glass/stained glass',
            'ceramics/pottery','music','theatre/television/film'
        ) THEN 1.05

        -- Science & Research
        WHEN [Current Job Department] IN (
            'academic','analytical','research (life sciences)','research (medical)',
            'research (maths)','research (physical sciences)','molecular'
        ) THEN 1.20
        
        -- Business / Corporate
        WHEN [Current Job Department] IN (
            'corporate','Civil Service','government','charities/voluntary organisations',
            'political party','trade union','commercial','commercial/residential','company'
        ) THEN 1.15
        
        -- Finance / Chartered
        WHEN [Current Job Department] IN (
            'chartered','chartered public finance','chartered certified',
            'chartered management','quantity'
        ) THEN 1.30
        
        -- Construction / Environment
        WHEN [Current Job Department] IN (
            'building','building services','building control','rural practice',
            'land','land/geomatics','hydrographic','environmental','water',
            'water quality','site','planning and development'
        ) THEN 1.10
        
        -- Retail / Services
        WHEN [Current Job Department] IN (
            'retail','fast food','wellsite','operational','community','amenity','sports'
        ) THEN 0.90
        
        -- Default
        ELSE 1
    END
	) AS [Candidate Fit Score],
	CASE 
		WHEN [Application Status] = 'Offered' THEN 1
		ELSE 0
	END AS [Is Selected Flag],
	CASE 
		WHEN [Application Status] = 'Rejected' THEN 1
		ELSE 0
	END AS [Is Rejected Flag]

FROM 
(
SELECT 
	ApplicantID,
	[Applicant Full Name],
	[Application Status],
	[Application Date],
	YEAR([Application Date]) AS [Application Year],
	MONTH([Application Date]) AS [Application Month],
	DATEDIFF(DAY,[Application Date],GETDATE()) AS [Days Since Application],
	Gender,
	[Age At Application],
	[Education Level],
	[Years Of Experience],
	[Current Job Department],
	[Desired Salary],
	CASE
		WHEN [Education Level] = 'PhD' THEN 5
		WHEN [Education Level] = 'Master''s Degree' THEN 4
		WHEN [Education Level] = 'Bachelor''s Degree' THEN 3
		WHEN [Education Level] = 'High School' THEN 1
		ELSE 0
	END AS [Education Score],
	CASE
		WHEN [Years Of Experience] >= 11 THEN 5
		WHEN [Years Of Experience] >= 8 THEN 4
		WHEN [Years Of Experience] >= 5 THEN 3
		WHEN [Years Of Experience] >= 2 THEN 2
		ELSE 1
	END AS [Experience Score],
	(
    (CASE
        WHEN [Education Level] = 'PhD' THEN 5
        WHEN [Education Level] = 'Master''s Degree' THEN 4
        WHEN [Education Level] = 'Bachelor''s Degree' THEN 3
        WHEN [Education Level] = 'High School' THEN 1
        ELSE 0
    END * 0.4)
    +
    (CASE
        WHEN [Years Of Experience] >= 11 THEN 5
        WHEN [Years Of Experience] >= 8 THEN 4
        WHEN [Years Of Experience] >= 5 THEN 3
        WHEN [Years Of Experience] >= 2 THEN 2
        ELSE 1
    END * 0.6)
	) AS [Candidate Score]

FROM gold.vw_hr_recruitment_data) recruitment_data)recruitment_data)recruitment_data;

--SELECT distinct [Current Job Department] FROM GOLD.vw_hr_recruitment_data;



select * from gold.vw_hr_recruitment_data_Report;
