/*************************************************** [ Information ] *********************************************************

	Application										 :  Geographical Penetration & Product Mix 

	Version											 :  1.0

	Author											 :  Sanket Mishra 

	Date Created									 :  07-July-2013

	Description										 :  This SQL query summarizes the data by postal code on 
														the following parameters :
														1. Number of distinct buyers
														2. Average amount of transactions
														3. Total Revenue
														4. Most popular product category 

	Assumptions										 :  In order to calculate the most Popular Product Category,
														the product that fetches maximum revenue for the particular
														Postal Code, has been considered.

	Filters	Used									 :  1. For US territories Only
														2. Order Date

**************************************************** [ Start of Code ] *********************************************************/

SELECT
	 Agg_Details.StateProvinceCode					 AS "State Code"
	,Agg_Details.PostalCode							 AS "Postal Code"
	,Agg_Details.Distinct_Buyers					 AS "Distinct Buyers"
	,Agg_Details.Avg_Transactions_Amt				 AS "Avg Transaction Amt"
	,Agg_Details.Total_Revenue						 AS "Total Revenue"
	,Popular_Product.Product_Category				 AS "Popular Product" 

FROM
	(
	-- Inline table to fetch Aggregate Details based on State Code and Postal Code --
	SELECT
		 GEO.StateProvinceCode						 AS StateProvinceCode
		,GEO.PostalCode								 AS PostalCode
		,COUNT( DISTINCT FACT_SALES.CustomerPONumber) 
													 AS Distinct_Buyers
		,CAST(AVG(FACT_SALES.SalesAmount) AS DECIMAL(10,2))
													 AS Avg_Transactions_Amt
		,CAST(SUM(FACT_SALES.SalesAmount) AS DECIMAL(10,2))	
													 AS Total_Revenue
	
	FROM
		[dbo].[FactResellerSales] FACT_SALES

		-- Joins To Get Product Details
		INNER JOIN [dbo].[DimProduct] PRODUCT
		ON FACT_SALES.ProductKey					= PRODUCT.ProductKey
		INNER JOIN [dbo].[DimProductSubcategory] PROD_SUB_CTGRY
		ON PRODUCT.ProductSubcategoryKey			= PROD_SUB_CTGRY.ProductSubcategoryKey
		INNER JOIN [dbo].[DimProductCategory] PROD_CTGRY
		ON PROD_SUB_CTGRY.ProductCategoryKey		= PROD_CTGRY.ProductCategoryKey

		-- Joins to get details on Postal Code and State Code
		INNER JOIN [dbo].[DimReseller] RESELLER
		ON FACT_SALES.ResellerKey					= RESELLER.ResellerKey
		INNER JOIN [dbo].[DimGeography] GEO
		ON RESELLER.GeographyKey					= GEO.GeographyKey	

	WHERE
		GEO.CountryRegionCode						=  'US'			 -- For US Territories Only
		AND CAST(FACT_SALES.OrderDate AS Date)		>= '2005-01-01'  -- Date filter for Order Date

	GROUP BY
		 GEO.StateProvinceCode
		,GEO.PostalCode

	-- End of Inline Table Agg_Details  --
	) Agg_Details
	
	INNER JOIN 

	(
	-- Inline table to fetch the most Popular Product for State Code and Postal Code based on Total Revenue -- 
	SELECT
		 GEO.StateProvinceCode						 AS StateProvinceCode
		,GEO.PostalCode								 AS PostalCode
		,PROD_CTGRY.EnglishProductCategoryName		 AS Product_Category
		,SUM(FACT_SALES.SalesAmount)				 AS Total_Revenue
		,RANK() OVER 
		(PARTITION BY StateProvinceCode,PostalCode  ORDER BY SUM(FACT_SALES.SalesAmount) DESC) 
													 AS Rank
	FROM
		[dbo].[FactResellerSales] FACT_SALES

		-- Joins To Get Product Details
		INNER JOIN [dbo].[DimProduct] PRODUCT
		ON FACT_SALES.ProductKey					= PRODUCT.ProductKey
		INNER JOIN [dbo].[DimProductSubcategory] PROD_SUB_CTGRY
		ON PRODUCT.ProductSubcategoryKey			= PROD_SUB_CTGRY.ProductSubcategoryKey
		INNER JOIN [dbo].[DimProductCategory] PROD_CTGRY
		ON PROD_SUB_CTGRY.ProductCategoryKey		= PROD_CTGRY.ProductCategoryKey

		-- Joins to get details on Postal Code and State Code
		INNER JOIN [dbo].[DimReseller] RESELLER
		ON FACT_SALES.ResellerKey					= RESELLER.ResellerKey
		INNER JOIN [dbo].[DimGeography] GEO
		ON RESELLER.GeographyKey					= GEO.GeographyKey	

	WHERE
		GEO.CountryRegionCode						=  'US'			 -- For US Territories Only
		AND CAST(FACT_SALES.OrderDate AS Date)		>= '2005-01-01'  -- Date filter for Order Date

	GROUP BY
		 GEO.StateProvinceCode
		,GEO.PostalCode
		,PROD_CTGRY.EnglishProductCategoryName

	--End of Inline table Popular_Product
	) Popular_Product

	ON Agg_Details.PostalCode						= Popular_Product.PostalCode
	AND Agg_Details.StateProvinceCode				= Popular_Product.StateProvinceCode

WHERE
	Popular_Product.Rank = 1
	--AND Agg_Details.StateProvinceCode = 'AZ'

ORDER BY
	 Agg_Details.StateProvinceCode
	,Agg_Details.PostalCode;

/*************************************************** [ End of Code ] *********************************************************/