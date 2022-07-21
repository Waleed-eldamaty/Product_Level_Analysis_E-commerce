-- Main Objective (1): Product-Level Sales Analysis

-- Task: An Email was sent on January 04-2013 from the CEO: Cindy Sharp and it includes the following:

-- We’re about to launch a new product, and I’d like to do a deep dive on our current flagship product.
-- Can you please pull monthly trends to date for number of sales , total revenue , and total margin generated for the business?
-- -----------------------------------------------------------------------------------------------------------------------------

-- Solution Starts:

SELECT
Year(created_at) AS yr,
Month(created_at) AS mo,
COUNT(DISTINCT order_id) AS Number_of_Orders,
SUM(price_usd) AS Total_Revenue,
SUM(price_usd-cogs_usd) AS Total_Margin
FROM orders
WHERE created_at < '2013-01-04'
GROUP BY 1,2;

-- Conlcusion to question(1):
-- There is a general growth in the number of orders, total revenue and total margin
-- -----------------------------------------------------------------------------------------------------------------------------

-- Main Objective (2): Product Launch Sales Analysis

-- Task: An Email was sent on April 05-2013 from the CEO: Cindy Sharp and it includes the following:

-- We launched our second product back on January 6th . Can you pull together some trended analysis?
-- I’d like to see monthly order volume , overall conversion rates , revenue per session , and a breakdown of sales by product , all for the time period since April 1, 2012
-- -----------------------------------------------------------------------------------------------------------------------------

-- Solution Starts:

SELECT
YEAR(website_sessions.created_at) as yr,
Month(website_sessions.created_at) as mo,
COUNT(DISTINCT website_sessions.website_session_id) as Number_of_sessions, 
COUNT(DISTINCT orders.order_id) as Order_Volume,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) as Conversion_Rate,
SUM(orders.price_usd)/ COUNT(DISTINCT website_sessions.website_session_id) AS Revenue_Per_Session,
COUNT(DISTINCT CASE WHEN primary_product_id=1 THEN order_id ELSE NULL END) AS product_one_orders, -- Sales By Product
COUNT(DISTINCT CASE WHEN primary_product_id=2 THEN order_id ELSE NULL END) AS product_two_orders -- Sales By Product
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id=orders.website_session_id
WHERE website_sessions.created_at BETWEEN '2012-04-01' AND '2013-04-05'
GROUP BY 1,2;

-- Conlcusion to question(2):
-- The Conversion rate and revenue per session are improving over time
-- We need to identify if the growth is due to the new product launch in January 2013 or just a continuation of the overall bussiness improvements.
-- -----------------------------------------------------------------------------------------------------------------------------

-- Main Objective (3): Product Pathing Analysis

-- Task: An Email was sent on April 06-2013 from the Website Manager: Morgan Rockwell and it includes the following:

-- Now that we have a new product, I’m thinking about our user path and conversion funnel. Let’s look at sessions which hit the /products page and see where they went next .
-- Could you please pull clickthrough rates from /products since the new product launch on January 6 th 2013 , by product, and compare to the 3 months leading up to launch as a baseline ?
-- -----------------------------------------------------------------------------------------------------------------------------

-- Solution Starts:

-- To solve this we are going to do the following:
-- STEP 1: Find the relevant /products pageviews with website_session_ID
-- STEP 2: Find the next pageview ID that occurs after the product pageview
-- STEP 3: Find the pageview_url associated with any applicable next pageview_ID
-- STEP 4: Summarize the data and analyze pre vs post periods

-- STEP 1: Find the relevant /products pageviews with website_session_ID

CREATE TEMPORARY TABLE Products_Pageviews
SELECT
website_session_id,
website_pageview_id,
created_at,
CASE 
	WHEN created_at < '2013-01-06' THEN ' A. Pre_Product_2'
	WHEN created_at >= '2013-01-06' THEN ' A. Post_Product_2'
	ELSE 'Check Logic'
END as Time_Period
FROM website_pageviews
WHERE created_at < '2013-04-06' -- Date of email 
AND created_at > '2012-10-06' -- 3 Months before the launch date of the 2nd product on January 6th 2013
AND pageview_url ='/products';

-- For QA
SELECT*FROM Products_Pageviews;


-- STEP 2: Find the next pageview ID that occurs after the product pageview
CREATE TEMPORARY TABLE Sessions_with_next_pageview_id
SELECT
Products_Pageviews.Time_Period,
Products_Pageviews.website_session_id,
MIN(website_pageviews.website_pageview_id) AS min_next_pageview_id -- the next pageview that happened after the product page. Also, The Null in the result indicate the person left after the product page and didnt clickthrough
FROM Products_Pageviews
LEFT JOIN website_pageviews
ON Products_Pageviews.website_session_id=website_pageviews.website_session_id
AND website_pageviews.website_pageview_id > Products_Pageviews.website_pageview_id -- The join will happen for pageviews that happened after the products_pageviews
GROUP BY 1,2;

-- For QA
SELECT*FROM Sessions_with_next_pageview_id;

-- STEP 3: Find the pageview_url associated with any applicable next pageview_ID
CREATE TEMPORARY TABLE sessions_w_next_pageview_url
SELECT
Sessions_with_next_pageview_id.Time_period,
Sessions_with_next_pageview_id.website_session_id,
website_pageviews.pageview_url as Next_pageview_url
FROM Sessions_with_next_pageview_id
LEFT JOIN website_pageviews
ON Sessions_with_next_pageview_id.min_next_pageview_id=website_pageviews.website_pageview_id;

-- For QA
SELECT*FROM sessions_w_next_pageview_url;

-- STEP 4: Summarize the data and analyze pre vs post periods
SELECT
Time_period,
COUNT(DISTINCT website_session_id) AS number_of_sessions,
COUNT(DISTINCT CASE WHEN Next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) AS Sessions_With_Next_pageview,
COUNT(DISTINCT CASE WHEN Next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS Percentage_with_Next_pageview,
COUNT(DISTINCT CASE WHEN Next_pageview_url ='/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS Sessions_to_mr_fuzzy,
COUNT(DISTINCT CASE WHEN Next_pageview_url ='/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS Percentage_to_Mr_Fuzzy,
COUNT(DISTINCT CASE WHEN Next_pageview_url ='/the-forever-love-bear' THEN website_session_id ELSE NULL END) AS Sessions_to_forever_lovebear,
COUNT(DISTINCT CASE WHEN Next_pageview_url ='/the-forever-love-bear' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS Percentage_to_forever_lovebear
FROM sessions_w_next_pageview_url
GROUP BY 1;

-- Conlcusion to question(3):
-- The % of product pageview that clicked to Mr Fuzzy has gone down since the launch of the Love Bear but the overall clickthrough rate has gone up
-- -----------------------------------------------------------------------------------------------------------------------------

-- Main Objective (4): Product Conversion Funnels

-- Task: An Email was sent on April 10-2013 from the Website Manager: Morgan Rockwell and it includes the following:

-- I’d like to look at our two products since January 6th and analyze the conversion funnels from each product page to conversion.
-- It would be great if you could produce a comparison between the two conversion funnels, for all website traffic.
-- -----------------------------------------------------------------------------------------------------------------------------

-- Solution Starts:

-- To solve this we are going to do the following:
-- STEP 1: Find all pageviews for relevant sessions
-- STEP 2: figure out which pageview url to look for
-- STEP 3: pull all pageviews and identify the funnel steps
-- STEP 4: create the session-level conversion funnel view
-- STEP 5: aggreagate the date to asses funnel performance

-- STEP 1: Find all pageviews for relevant sessions

CREATE TEMPORARY TABLE Sessions_Seeing_Product_page
SELECT
website_session_id,
website_pageview_id,
pageview_url AS product_page_seen
FROM website_pageviews
WHERE website_pageviews.created_at BETWEEN '2013-01-06' AND '2013-04-10'
AND website_pageviews.pageview_url IN ('/the-original-mr-fuzzy','/the-forever-love-bear');

-- For QA
SELECT*FROM Sessions_Seeing_Product_page;

-- STEP 2: figure out which pageview url to look for to build our funnel

SELECT
website_pageviews.pageview_url
FROM Sessions_Seeing_Product_page
LEFT JOIN website_pageviews
ON Sessions_Seeing_Product_page.website_pageview_id<website_pageviews.website_pageview_id -- We are limitting just to website pageviews which happened after the customer saw the prodcut
AND Sessions_Seeing_Product_page.website_session_id=website_pageviews.website_session_id
GROUP BY 1; -- We will use the outcome of this query (all the URLs the customer saw during this period) to build the conversion funnel

-- Pageview Level results and flagging it based on the URLs results of the previous query
SELECT
Sessions_Seeing_Product_page.website_session_id,
Sessions_Seeing_Product_page.product_page_seen,
CASE WHEN pageview_url ='/cart' THEN 1 ELSE 0 END as Cart_page,
CASE WHEN pageview_url ='/shipping' THEN 1 ELSE 0 END as Shipping_page,
CASE WHEN pageview_url ='/billing-2' THEN 1 ELSE 0 END as Billing_page,
CASE WHEN pageview_url ='/thank-you-for-your-order' THEN 1 ELSE 0 END as thank_you_page
FROM Sessions_Seeing_Product_page
LEFT JOIN website_pageviews
ON Sessions_Seeing_Product_page.website_pageview_id<website_pageviews.website_pageview_id 
AND Sessions_Seeing_Product_page.website_session_id=website_pageviews.website_session_id
Order BY 1; -- We have multiple records for the same website_session_id because we joined with pageviews which have multiple pageviews per session
-- For example, website session id 63513 have 4 records which happened after the product page ( 1 is the cart page, 1 is the shipping page, 1 is the billing page, 1 is the thank you page)

-- Using the previous query as a subquery
-- to collapse the records (4 records of website_session_id 63513 into 1 record) into a website_session_id Level Summary where we will have flags wether they made it into this pages or not

CREATE TEMPORARY TABLE Sessions_product_level_made_it_w_flags
SELECT
website_session_id,
CASE
WHEN product_page_seen = '/the-original-mr-fuzzy' then 'MrFuzzy' -- to make it cleaner to read
WHEN product_page_seen = '/the-forever-love-bear' THEN 'lovebear' -- to make it cleaner to read 
ELSE 'check logic'
END AS Product_Seen,
MAX(Cart_page) AS Cart_made_it,
MAX(Shipping_page) AS Shipping_made_it,
MAX(Billing_page) AS Billing_made_it,
MAX(thank_you_page) AS thankyou_made_it

FROM(
SELECT
Sessions_Seeing_Product_page.website_session_id,
Sessions_Seeing_Product_page.product_page_seen,
CASE WHEN pageview_url ='/cart' THEN 1 ELSE 0 END as Cart_page,
CASE WHEN pageview_url ='/shipping' THEN 1 ELSE 0 END as Shipping_page,
CASE WHEN pageview_url ='/billing-2' THEN 1 ELSE 0 END as Billing_page,
CASE WHEN pageview_url ='/thank-you-for-your-order' THEN 1 ELSE 0 END as thank_you_page
FROM Sessions_Seeing_Product_page
LEFT JOIN website_pageviews
ON Sessions_Seeing_Product_page.website_pageview_id<website_pageviews.website_pageview_id 
AND Sessions_Seeing_Product_page.website_session_id=website_pageviews.website_session_id
) AS pageview_level
GROUP BY website_session_id,
CASE
WHEN product_page_seen = '/the-original-mr-fuzzy' then 'MrFuzzy'
WHEN product_page_seen = '/the-forever-love-bear' THEN 'lovebear'
ELSE 'check logic'
END;

-- For QA
SELECT* FROM Sessions_product_level_made_it_w_flags;

-- Final outcome Part 1:
SELECT
Product_Seen,
COUNT(DISTINCT website_session_id) AS Number_of_sessions,
COUNT(DISTINCT CASE WHEN Cart_made_it = 1 THEN website_session_id ELSE NULL END) AS  To_Cart,
COUNT(DISTINCT CASE WHEN Shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS  To_Shipping,
COUNT(DISTINCT CASE WHEN Billing_made_it = 1 THEN website_session_id ELSE NULL END) AS  To_Billing,
COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS  To_thankyou
FROM Sessions_product_level_made_it_w_flags
GROUP BY Product_Seen ;

-- Final Outcome Part 2: click_rates

SELECT
Product_Seen,
COUNT(DISTINCT website_session_id) AS Number_of_sessions,
COUNT(DISTINCT CASE WHEN Cart_made_it = 1 THEN website_session_id ELSE NULL END)/ COUNT(DISTINCT website_session_id) AS  Product_page_click_rate,
COUNT(DISTINCT CASE WHEN Shipping_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN Cart_made_it = 1 THEN website_session_id ELSE NULL END) AS  Cart_page_click_rate,
COUNT(DISTINCT CASE WHEN Billing_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN Shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS  Shipping_page_click_rate,
COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN Billing_made_it = 1 THEN website_session_id ELSE NULL END) AS  Billing_page_click_rate
FROM Sessions_product_level_made_it_w_flags
GROUP BY Product_Seen ;

-- Conlcusion to question(4):
-- Love Bear has a better click rate to the cart page and similar rates throughout the rest of the funnel
-- -----------------------------------------------------------------------------------------------------------------------------

-- Main Objective (5): Cross-Sell Analysis

-- Task: An Email was sent on Novmber 22-2013 from the CEO: Cindy Sharp and it includes the following:

-- On September 25 th we started giving customers the option to add a 2 nd product while on the /cart page . Morgan says this has been positive, but I’d like your take on it.
-- Could you please compare the month before vs the month after the change ? I’d like to see CTR from the /cart page , Avg Products per Order , AOV , and overall revenue per /cart page view
-- -----------------------------------------------------------------------------------------------------------------------------

-- Solution Starts:

-- To solve this we are going to do the following:
-- STEP 1: Identify relevant /cart page views and their sessions
-- STEP 2: See which of those /cart sessions clicked through to the shipping page
-- STEP 3: Find the orders associated with the /cart sessions. Analyze products purchased and AOV
-- STEP 4: Aggregate and analyze summary of our findings

CREATE TEMPORARY TABLE Sessions_Seeing_Cart
SELECT
CASE 
	WHEN created_at < '2013-09-25' THEN 'Pre_Cross_Sell'
	WHEN created_at >= '2013-09-25' THEN 'Post_Cross_Sell'
	ELSE 'Check logic'
END AS Time_Period,
website_pageviews.website_session_id AS cart_session_id,
website_pageviews.website_pageview_id AS cart_pageview_id
FROM website_pageviews
WHERE created_at BETWEEN '2013-08-25' AND '2013-10-25'
AND pageview_url = '/cart';

-- For QA
SELECT*FROM Sessions_Seeing_Cart;

CREATE TEMPORARY TABLE Cart_Sessions_Seeing_Another_Page -- After the cart
-- To create the flagging system later on in order to identify sessions that did make it to another page
SELECT
Sessions_Seeing_Cart.Time_period,
Sessions_Seeing_Cart.cart_session_id,
MIN(website_pageviews.website_pageview_id) AS Pageview_ID_After_Cart
FROM Sessions_Seeing_Cart
LEFT JOIN website_pageviews
ON website_pageviews.website_pageview_id > Sessions_Seeing_Cart.cart_pageview_id
AND website_pageviews.website_session_id = Sessions_Seeing_Cart.cart_session_id
GROUP BY 1,2
HAVING MIN(website_pageviews.website_pageview_id) IS NOT NULL ; -- To remove null values which indicate customers who left on the /cart page


-- For QA
SELECT*FROM Cart_Sessions_Seeing_Another_Page;

CREATE TEMPORARY TABLE  pre_post_sessions_orders
-- To identify orders placed by Sessions Seeing Cart, we use Inner Join with orders table
SELECT
Sessions_Seeing_Cart.Time_Period,
Sessions_Seeing_Cart.cart_session_id,
Orders.order_id,
Orders.items_purchased,
Orders.price_usd
FROM Sessions_Seeing_Cart
INNER JOIN orders -- To get sessions that only had orders, No Null values. Try with Left Join and see the difference
ON Sessions_Seeing_Cart.cart_session_id=orders.website_session_id;

-- For QA
SELECT*FROM pre_post_sessions_orders;

-- We will connect the sessions seeing cart table with the 2 newly created tables ( cart sessions seeing another page & pre and post sessions orders) To check which session Clicked to another page AND Placed an Order
SELECT 
Sessions_Seeing_Cart.Time_Period,
Sessions_Seeing_Cart.cart_session_id,
CASE WHEN Cart_Sessions_Seeing_Another_Page.cart_session_id IS NULL THEN 0 ELSE 1 END AS Clicked_to_another_page,
CASE WHEN pre_post_sessions_orders.order_id IS NULL THEN 0 ELSE 1 END AS Placed_Order,
pre_post_sessions_orders.items_purchased,
pre_post_sessions_orders.price_usd
FROM Sessions_Seeing_Cart
LEFT JOIN Cart_Sessions_Seeing_Another_Page
ON Sessions_Seeing_Cart.cart_session_id=Cart_Sessions_Seeing_Another_Page.cart_session_id
LEFT JOIN pre_post_sessions_orders
ON Sessions_Seeing_Cart.cart_session_id=pre_post_sessions_orders.cart_session_id
ORDER BY cart_session_id; -- Next, we will use this Query as a subquery

SELECT
Time_period,
COUNT(DISTINCT cart_session_id) AS Number_of_Cart_Sessions,
SUM(Clicked_to_another_page) AS Clickthroughs,
SUM(Clicked_to_another_page)/COUNT(DISTINCT cart_session_id) AS Cart_Clickthrough_Rate,
SUM(Placed_order) AS Number_of_Orders_Placed,
SUM(items_purchased) AS Products_purchased,
SUM(items_purchased)/SUM(Placed_order) AS Products_Per_Order,
SUM(price_usd) AS Revenue,
SUM(price_usd)/ SUM(Placed_order) AS Average_Order_Value_AOV,
SUM(price_usd)/ COUNT(DISTINCT cart_session_id) AS Revenue_Per_Cart_page_View
FROM(
SELECT 
Sessions_Seeing_Cart.Time_Period,
Sessions_Seeing_Cart.cart_session_id,
CASE WHEN Cart_Sessions_Seeing_Another_Page.cart_session_id IS NULL THEN 0 ELSE 1 END AS Clicked_to_another_page,
CASE WHEN pre_post_sessions_orders.order_id IS NULL THEN 0 ELSE 1 END AS Placed_Order,
pre_post_sessions_orders.items_purchased,
pre_post_sessions_orders.price_usd
FROM Sessions_Seeing_Cart
LEFT JOIN Cart_Sessions_Seeing_Another_Page
ON Sessions_Seeing_Cart.cart_session_id=Cart_Sessions_Seeing_Another_Page.cart_session_id
LEFT JOIN pre_post_sessions_orders
ON Sessions_Seeing_Cart.cart_session_id=pre_post_sessions_orders.cart_session_id
ORDER BY cart_session_id) AS Full_Data
GROUP BY Time_Period;

-- Conlcusion to question(5):
-- CTR from the /cart page , Avg Products per Order , AOV , and overall revenue per /cart page view went slightly up since the cross-sell feature was added.
-- -----------------------------------------------------------------------------------------------------------------------------

-- Main Objective (6): Portfolio Expansion Analysis

-- Task: An Email was sent on January 12-2014 from the CEO: Cindy Sharp and it includes the following:

-- On December 12th 2013, we launched a third product targeting the birthday gift market (Birthday Bear).
-- Could you please run a pre post analysis comparing the month before vs. the month after , in terms of session to order conversion rate , AOV , products per order , and revenue per session
-- -----------------------------------------------------------------------------------------------------------------------------

-- Solution Starts:

SELECT
CASE
WHEN website_sessions.created_at < '2013-12-12' THEN 'Pre_Birthday_Bear'
WHEN website_sessions.created_at >= '2013-12-12' THEN 'Post_Birthday_Bear'
ELSE 'Check logic'
END AS Time_Period,
COUNT(DISTINCT website_sessions.website_session_id) AS Number_of_Sessions,
COUNT(DISTINCT orders.order_id) AS Number_of_Orders,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS Conversion_Rate,
SUM(orders.price_usd) AS Revenue,
SUM(orders.price_usd)/COUNT(DISTINCT orders.order_id) AS AOV,
SUM(orders.items_purchased) AS Products_Purchased,
SUM(orders.items_purchased)/COUNT(DISTINCT orders.order_id) AS Products_per_Order,
SUM(orders.price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS Revenue_Per_Session
FROM website_sessions
LEFT JOIN Orders
ON website_sessions.website_session_id=orders.website_session_id
WHERE website_sessions.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY 1;

-- Conlcusion to question(6):
-- All the metrics (session to order conversion rate , AOV , products per order , and revenue per session) have improved since the launch of the third product
-- -----------------------------------------------------------------------------------------------------------------------------

-- Main Objective (7): Product Refund Rates

-- Task: An Email was sent on October 15-2014 from the CEO: Cindy Sharp and it includes the following:

-- Our Mr. Fuzzy supplier had some quality issues which weren’t corrected until September 2013. Then they had a major problem where the bears’ arms were falling off in Aug/Sep 2014.
-- As a result, we replaced them with a new supplier on September 16, 2014
-- Can you please pull monthly product refund rates, by product, and confirm our quality issues are now fixed
-- -----------------------------------------------------------------------------------------------------------------------------

-- Solution Starts:

SELECT
YEAR(order_items.created_at) as yr,
MONTH(order_items.created_at) as mo,
COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_items.order_item_id ELSE NULL END ) AS P1_orders, -- Total P1 Items Sold

COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_item_refunds.order_item_id ELSE NULL END )/ 
COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_items.order_item_id ELSE NULL END ) AS P1_Refund_Rates, -- Total Number of Refuned P1 Items / Total P1 Items Sold to get P1 Refund Rate

COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_items.order_item_id ELSE NULL END ) AS P2_Orders,

COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_items.order_item_id ELSE NULL END ) AS P3_orders,

COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_item_refunds.order_item_id ELSE NULL END )/
COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_items.order_item_id ELSE NULL END ) AS P3_Refund_Rates,

COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_items.order_item_id ELSE NULL END ) AS P4_orders,

COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_item_refunds.order_item_id ELSE NULL END )/
COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_items.order_item_id ELSE NULL END ) AS P4_Refund_Rates
FROM order_items
LEFT JOIN order_item_refunds
ON order_items.order_item_id=order_item_refunds.order_item_id
WHERE order_items.created_at  <'2014-10-15'
GROUP BY 1,2;

-- Conlcusion to question(7):
-- Looks like the refund rates for Mr. Fuzzy did go down after the initial improvements in September 2013,
-- but refund rates were terrible in August and September, as expected (13 14%).
-- Seems like the new supplier is doing much better so far, and the other products look okay too.
-- -----------------------------------------------------------------------------------------------------------------------------









