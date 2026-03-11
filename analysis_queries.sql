-- =============================================================================
-- CUSTOMER SUPPORT OPERATIONS ANALYSIS
-- Tech Product Support Tickets (2020-2021)
-- =============================================================================

-- =============================================================================
-- SECTION 1: DATA OVERVIEW
-- =============================================================================

-- Total ticket counts and status breakdown
SELECT 
    COUNT(*) as total_tickets,
    SUM(CASE WHEN status = 'Closed' THEN 1 ELSE 0 END) as closed_tickets,
    SUM(CASE WHEN status = 'Open' THEN 1 ELSE 0 END) as open_tickets,
    SUM(CASE WHEN status = 'Pending Customer Response' THEN 1 ELSE 0 END) as pending_tickets,
    ROUND(100.0 * SUM(CASE WHEN status = 'Closed' THEN 1 ELSE 0 END) / COUNT(*), 1) as resolution_rate_pct
FROM tickets;

-- Date range
SELECT 
    MIN(ticket_date) as earliest_ticket,
    MAX(ticket_date) as latest_ticket,
    COUNT(DISTINCT ticket_month) as months_covered
FROM tickets;

-- =============================================================================
-- SECTION 2: CHANNEL PERFORMANCE
-- =============================================================================

-- Channel volume and performance metrics
SELECT 
    channel,
    COUNT(*) as tickets,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM tickets), 1) as pct_of_total,
    ROUND(AVG(first_response_hours), 1) as avg_response_hours,
    ROUND(100.0 * SUM(CASE WHEN sla_met = 1 THEN 1 ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN sla_met IS NOT NULL THEN 1 ELSE 0 END), 0), 1) as sla_compliance_pct,
    ROUND(AVG(csat_score), 2) as avg_csat
FROM tickets
GROUP BY channel
ORDER BY tickets DESC;

-- Channel performance for closed tickets only
SELECT 
    channel,
    COUNT(*) as closed_tickets,
    ROUND(AVG(resolution_hours), 1) as avg_resolution_hours,
    ROUND(AVG(csat_score), 2) as avg_csat,
    ROUND(100.0 * SUM(CASE WHEN csat_score >= 4 THEN 1 ELSE 0 END) / COUNT(*), 1) as satisfied_pct
FROM tickets
WHERE status = 'Closed'
GROUP BY channel
ORDER BY avg_csat DESC;

-- =============================================================================
-- SECTION 3: PRIORITY ANALYSIS
-- =============================================================================

-- Priority distribution and SLA performance
SELECT 
    t.priority,
    COUNT(*) as tickets,
    s.response_target_hours as sla_target,
    ROUND(AVG(t.first_response_hours), 1) as avg_response_hours,
    ROUND(100.0 * SUM(CASE WHEN t.sla_met = 1 THEN 1 ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN t.sla_met IS NOT NULL THEN 1 ELSE 0 END), 0), 1) as sla_met_pct,
    SUM(CASE WHEN t.sla_met = 0 THEN 1 ELSE 0 END) as sla_breaches
FROM tickets t
LEFT JOIN sla_targets s ON t.priority = s.priority
GROUP BY t.priority
ORDER BY CASE t.priority 
    WHEN 'Critical' THEN 1 WHEN 'High' THEN 2 WHEN 'Medium' THEN 3 ELSE 4 END;

-- Priority by channel (cross-tabulation)
SELECT 
    channel,
    SUM(CASE WHEN priority = 'Critical' THEN 1 ELSE 0 END) as critical,
    SUM(CASE WHEN priority = 'High' THEN 1 ELSE 0 END) as high,
    SUM(CASE WHEN priority = 'Medium' THEN 1 ELSE 0 END) as medium,
    SUM(CASE WHEN priority = 'Low' THEN 1 ELSE 0 END) as low
FROM tickets
GROUP BY channel;

-- =============================================================================
-- SECTION 4: TICKET TYPE ANALYSIS
-- =============================================================================

-- Ticket type performance
SELECT 
    ticket_type,
    COUNT(*) as tickets,
    ROUND(100.0 * SUM(CASE WHEN status = 'Closed' THEN 1 ELSE 0 END) / COUNT(*), 1) as resolution_rate,
    ROUND(AVG(resolution_hours), 1) as avg_resolution_hours,
    ROUND(AVG(csat_score), 2) as avg_csat
FROM tickets
GROUP BY ticket_type
ORDER BY tickets DESC;

-- Ticket type by channel
SELECT 
    ticket_type,
    channel,
    COUNT(*) as tickets,
    ROUND(AVG(csat_score), 2) as avg_csat
FROM tickets
GROUP BY ticket_type, channel
ORDER BY ticket_type, tickets DESC;

-- =============================================================================
-- SECTION 5: VOLUME TRENDS
-- =============================================================================

-- Monthly ticket volume
SELECT 
    ticket_month,
    COUNT(*) as tickets,
    ROUND(AVG(first_response_hours), 1) as avg_response_hours,
    ROUND(100.0 * SUM(CASE WHEN sla_met = 1 THEN 1 ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN sla_met IS NOT NULL THEN 1 ELSE 0 END), 0), 1) as sla_pct,
    ROUND(AVG(csat_score), 2) as avg_csat
FROM tickets
GROUP BY ticket_month
ORDER BY ticket_month;

-- Quarterly trends
SELECT 
    ticket_year,
    ticket_quarter,
    COUNT(*) as tickets,
    ROUND(100.0 * SUM(CASE WHEN status = 'Closed' THEN 1 ELSE 0 END) / COUNT(*), 1) as resolution_rate,
    ROUND(AVG(csat_score), 2) as avg_csat
FROM tickets
GROUP BY ticket_year, ticket_quarter
ORDER BY ticket_year, ticket_quarter;

-- Day of week patterns
SELECT 
    day_of_week,
    COUNT(*) as tickets,
    ROUND(AVG(first_response_hours), 1) as avg_response_hours,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM tickets), 1) as pct_of_total
FROM tickets
GROUP BY day_of_week
ORDER BY CASE day_of_week 
    WHEN 'Monday' THEN 1 WHEN 'Tuesday' THEN 2 WHEN 'Wednesday' THEN 3 
    WHEN 'Thursday' THEN 4 WHEN 'Friday' THEN 5 WHEN 'Saturday' THEN 6 ELSE 7 END;

-- Weekend vs Weekday
SELECT 
    CASE WHEN is_weekend = 1 THEN 'Weekend' ELSE 'Weekday' END as day_type,
    COUNT(*) as tickets,
    ROUND(AVG(first_response_hours), 1) as avg_response_hours,
    ROUND(AVG(csat_score), 2) as avg_csat
FROM tickets
GROUP BY is_weekend;

-- =============================================================================
-- SECTION 6: PRODUCT ANALYSIS
-- =============================================================================

-- Top products by ticket volume
SELECT 
    product,
    COUNT(*) as tickets,
    ROUND(100.0 * SUM(CASE WHEN status = 'Closed' THEN 1 ELSE 0 END) / COUNT(*), 1) as resolution_rate,
    ROUND(AVG(csat_score), 2) as avg_csat
FROM tickets
GROUP BY product
ORDER BY tickets DESC
LIMIT 15;

-- Products with lowest CSAT (minimum 50 tickets)
SELECT 
    product,
    COUNT(*) as tickets,
    ROUND(AVG(csat_score), 2) as avg_csat,
    ROUND(100.0 * SUM(CASE WHEN csat_score <= 2 THEN 1 ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN csat_score IS NOT NULL THEN 1 ELSE 0 END), 0), 1) as dissatisfied_pct
FROM tickets
GROUP BY product
HAVING COUNT(*) >= 50
ORDER BY avg_csat ASC
LIMIT 10;

-- =============================================================================
-- SECTION 7: CUSTOMER SATISFACTION ANALYSIS
-- =============================================================================

-- CSAT distribution
SELECT 
    csat_score,
    COUNT(*) as tickets,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM tickets WHERE csat_score IS NOT NULL), 1) as pct
FROM tickets
WHERE csat_score IS NOT NULL
GROUP BY csat_score
ORDER BY csat_score;

-- CSAT by response time bucket
SELECT 
    CASE 
        WHEN first_response_hours < 4 THEN '< 4 hours'
        WHEN first_response_hours < 8 THEN '4-8 hours'
        WHEN first_response_hours < 12 THEN '8-12 hours'
        WHEN first_response_hours < 24 THEN '12-24 hours'
        ELSE '24+ hours'
    END as response_bucket,
    COUNT(*) as tickets,
    ROUND(AVG(csat_score), 2) as avg_csat
FROM tickets
WHERE csat_score IS NOT NULL
GROUP BY response_bucket
ORDER BY CASE response_bucket 
    WHEN '< 4 hours' THEN 1 WHEN '4-8 hours' THEN 2 WHEN '8-12 hours' THEN 3 
    WHEN '12-24 hours' THEN 4 ELSE 5 END;

-- CSAT trends over time
SELECT 
    ticket_month,
    COUNT(*) as tickets_with_csat,
    ROUND(AVG(csat_score), 2) as avg_csat,
    ROUND(100.0 * SUM(CASE WHEN csat_score >= 4 THEN 1 ELSE 0 END) / COUNT(*), 1) as satisfied_pct
FROM tickets
WHERE csat_score IS NOT NULL
GROUP BY ticket_month
ORDER BY ticket_month;

-- =============================================================================
-- SECTION 8: CUSTOMER DEMOGRAPHICS
-- =============================================================================

-- Age group analysis
SELECT 
    CASE 
        WHEN customer_age < 25 THEN '18-24'
        WHEN customer_age < 35 THEN '25-34'
        WHEN customer_age < 45 THEN '35-44'
        WHEN customer_age < 55 THEN '45-54'
        WHEN customer_age < 65 THEN '55-64'
        ELSE '65+'
    END as age_group,
    COUNT(*) as tickets,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM tickets), 1) as pct_of_total,
    ROUND(AVG(csat_score), 2) as avg_csat
FROM tickets
GROUP BY age_group
ORDER BY age_group;

-- Gender analysis
SELECT 
    customer_gender,
    COUNT(*) as tickets,
    ROUND(AVG(csat_score), 2) as avg_csat,
    ROUND(100.0 * SUM(CASE WHEN status = 'Closed' THEN 1 ELSE 0 END) / COUNT(*), 1) as resolution_rate
FROM tickets
GROUP BY customer_gender;

-- Age group by channel preference
SELECT 
    CASE 
        WHEN customer_age < 35 THEN 'Under 35'
        WHEN customer_age < 55 THEN '35-54'
        ELSE '55+'
    END as age_bracket,
    channel,
    COUNT(*) as tickets
FROM tickets
GROUP BY age_bracket, channel
ORDER BY age_bracket, tickets DESC;

-- =============================================================================
-- SECTION 9: SLA DEEP DIVE
-- =============================================================================

-- SLA compliance by channel and priority
SELECT 
    channel,
    priority,
    COUNT(*) as tickets,
    ROUND(100.0 * SUM(CASE WHEN sla_met = 1 THEN 1 ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN sla_met IS NOT NULL THEN 1 ELSE 0 END), 0), 1) as sla_met_pct
FROM tickets
GROUP BY channel, priority
ORDER BY channel, CASE priority 
    WHEN 'Critical' THEN 1 WHEN 'High' THEN 2 WHEN 'Medium' THEN 3 ELSE 4 END;

-- Monthly SLA trends by priority
SELECT 
    ticket_month,
    ROUND(100.0 * SUM(CASE WHEN priority = 'Critical' AND sla_met = 1 THEN 1 ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN priority = 'Critical' THEN 1 ELSE 0 END), 0), 1) as critical_sla,
    ROUND(100.0 * SUM(CASE WHEN priority = 'High' AND sla_met = 1 THEN 1 ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN priority = 'High' THEN 1 ELSE 0 END), 0), 1) as high_sla
FROM tickets
GROUP BY ticket_month
ORDER BY ticket_month;

-- =============================================================================
-- SECTION 10: YEAR OVER YEAR COMPARISON
-- =============================================================================

-- Annual comparison
SELECT 
    ticket_year,
    COUNT(*) as tickets,
    ROUND(100.0 * SUM(CASE WHEN status = 'Closed' THEN 1 ELSE 0 END) / COUNT(*), 1) as resolution_rate,
    ROUND(AVG(first_response_hours), 1) as avg_response_hours,
    ROUND(100.0 * SUM(CASE WHEN sla_met = 1 THEN 1 ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN sla_met IS NOT NULL THEN 1 ELSE 0 END), 0), 1) as sla_pct,
    ROUND(AVG(csat_score), 2) as avg_csat
FROM tickets
GROUP BY ticket_year
ORDER BY ticket_year;

-- Q1 comparison (2020 vs 2021)
SELECT 
    ticket_year,
    COUNT(*) as q1_tickets,
    ROUND(AVG(csat_score), 2) as avg_csat
FROM tickets
WHERE ticket_quarter = 1
GROUP BY ticket_year;
