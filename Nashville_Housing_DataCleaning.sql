use Nashville_houseing_datacleaning

SELECT * 
FROM [dbo].[Nashville Housing Data for Data Cleaning]

-------------------------------------------------------------------------------------------------------------------------------
--POPULATE PROPERTY ADDRESS DATA


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(b.PropertyAddress,a.PropertyAddress) 
FROM [dbo].[Nashville Housing Data for Data Cleaning] a
JOIN [dbo].[Nashville Housing Data for Data Cleaning] b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE b.PropertyAddress is null


UPDATE b
SET PropertyAddress = ISNULL(b.PropertyAddress,a.PropertyAddress)
FROM [dbo].[Nashville Housing Data for Data Cleaning] a
JOIN [dbo].[Nashville Housing Data for Data Cleaning] b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID

---------------------------------------------------------------------------------------------------------------------------------------
--BREAKING OUT FULL ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS, CITY)

--PROPERTY ADDRESS

SELECT PropertyAddress
FROM [Nashville Housing Data for Data Cleaning]

SELECT SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)
AS ADDRESS,  SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress)+1 , LEN(PropertyAddress)) as Address
FROM [dbo].[Nashville Housing Data for Data Cleaning]

ALTER TABLE [Nashville Housing Data for Data Cleaning]
ADD PropertySplitAddress NVARCHAR(255)

UPDATE [Nashville Housing Data for Data Cleaning]
SET PropertySplitAddress = SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE [Nashville Housing Data for Data Cleaning]
ADD PropertyCity NVARCHAR (255)

UPDATE [Nashville Housing Data for Data Cleaning]
SET PropertyCity = SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress)+1 , LEN(PropertyAddress))


---SPLIT OWNER ADDRESS INTO 3 COLUMNS (ADDRESS, CITY, STATE)

SELECT PARSENAME (REPLACE(OwnerAddress,',','.'),3),
PARSENAME (REPLACE(OwnerAddress,',','.'),2),
PARSENAME (REPLACE(OwnerAddress,',','.'),1)
FROM [Nashville Housing Data for Data Cleaning]


ALTER TABLE [Nashville Housing Data for Data Cleaning]
ADD OwnerSplitAddress NVARCHAR(255)


UPDATE [Nashville Housing Data for Data Cleaning]
SET OwnerSplitAddress = PARSENAME (REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE [Nashville Housing Data for Data Cleaning]
ADD Ownersplitcity NVARCHAR(255)

UPDATE [Nashville Housing Data for Data Cleaning]
SET OwnerSplitCity = PARSENAME (REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE [Nashville Housing Data for Data Cleaning]
ADD OwnerSplitState NVARCHAR(255)

UPDATE [Nashville Housing Data for Data Cleaning]
SET OwnerSplitState = PARSENAME (REPLACE(OwnerAddress,',','.'),1)

SELECT * FROM [Nashville Housing Data for Data Cleaning]
-------------------------------------------------------------------------------------------------------------------------
--REMOVING DUPLICATES

With RowNumCte as 
(
SELECT *, ROW_NUMBER() OVER(
PARTITION BY ParcelID,
			PropertyAddress, 
			SaleDate,
			SalePrice,
			LegalReference
			ORDER BY 
				UniqueID) row_num 
FROM [Nashville Housing Data for Data Cleaning]
)
SELECT * FROM RowNumCte
WHERE row_num >1
ORDER BY PropertyAddress

-------------------------------------------------------------------------------------
--DELETE UNUSED COLUMNS
ALTER TABLE [Nashville Housing Data for Data Cleaning]
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


---------------------------------------------------------------------------------------------------
---ALTERNATIVELY SAVE DATA WITHOUT DUPLICATES INTO A VIEW
CREATE VIEW UniqueData as 
With RowNumCte as 
(
SELECT *, ROW_NUMBER() OVER(
PARTITION BY ParcelID,
			PropertyAddress, 
			SaleDate,
			SalePrice,
			LegalReference
			ORDER BY 
				UniqueID) row_num 
FROM [Nashville Housing Data for Data Cleaning]
)
SELECT *
FROM [Nashville Housing Data for Data Cleaning]
WHERE UniqueID NOT IN (
SELECT UniqueID 
FROM RowNumCte
WHERE row_num > 1
)