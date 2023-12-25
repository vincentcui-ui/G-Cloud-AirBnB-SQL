-- vcui
-- No admin access to prepWindowPrices, changed to prepWindowPrices2
DROP PROCEDURE IF EXISTS prepWindowPrices2;
USE db1;
-- Stored Prcoedure Code
DELIMITER //
CREATE PROCEDURE prepWindowPrices2(
	IN startDate DATE, IN endDate Date, IN duration integer)
	BEGIN

    -- Declare variables for loop
    DECLARE currentDate DATE;
    DECLARE loopEndDate DATE;

    -- Empty the cheapestPrices table
    DELETE FROM cheapestPrices;

    -- Initialize variables
    SET currentDate = startDate;
    SET loopEndDate = DATE_SUB(endDate, INTERVAL (duration-1) DAY);

    -- Loop through each day in the date range
    WHILE currentDate <= loopEndDate DO

        -- Insert cheapest places available for the given duration into cheapestPrices table
        INSERT INTO cheapestPrices(place_id, startDate, endDate, total)
        SELECT place_id, 
               currentDate, 
               DATE_ADD(currentDate, INTERVAL (duration-1) DAY),
               SUM(price) AS total_price
        FROM placeAvailability
        WHERE ava_date BETWEEN currentDate AND DATE_ADD(currentDate, INTERVAL (duration-1) DAY)
        AND available = 1
        GROUP BY place_id
        HAVING COUNT(ava_date) = duration
        ORDER BY total_price ASC
        LIMIT 1; -- Only insert the cheapest place

        -- Move to next date
        SET currentDate = DATE_ADD(currentDate, INTERVAL 1 DAY);

    END WHILE;

    -- Keep only the rows with the two lowest prices
    DELETE FROM cheapestPrices 
    WHERE total NOT IN (
        SELECT total FROM (
            SELECT DISTINCT total 
            FROM cheapestPrices 
            ORDER BY total ASC 
            LIMIT 1
        ) AS tmp
    );

	END //
DELIMITER ;
-- Calling code, remove the double dashes in the beginning when calling the stored procedure
SET @startDate = '2022-02-20';
SET @endDate = '2022-02-24';
SET @duration = 2;
CALL prepWindowPrices2(@startDate, @endDate, @duration);
SELECT * FROM cheapestPrices;