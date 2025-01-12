-- Standardize Data Format-------------------------------------------------------------------------------------------------------
SELECT SaleDate, CONVERT(SaleDate, datetime)
FROM nashvillehousingdata; -- Just an example, it's already date type
/*
Update nashvillehousingdata
SET SaleDate = CONVERT(SaleDate, datetime);
*/

-- Populate Property Address data-------------------------------------------------------------------------------------------------------
SELECT PropertyAddress
FROM nashvillehousingdata
WHERE PropertyAddress IS NULL; -- We don't know why they are NULL. We're trying to figure it out the features of this column.

SELECT *
FROM nashvillehousingdata
WHERE PropertyAddress IS NULL;

SELECT *
FROM nashvillehousingdata
ORDER BY ParcelID; -- We find that the same ParcelID has the same PropertyAddress

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress, b.PropertyAddress)
FROM nashvillehousingdata a
JOIN nashvillehousingdata b ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE nashvillehousingdata a
JOIN nashvillehousingdata b ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

-- Breaking out Address into Individual Columns (Address, City, State)-----------------------------------------------------------------------
-- First deal with the PropertyAddress
SELECT PropertyAddress
FROM nashvillehousingdata; -- The address includes street addree and city, delimiter is comma

SELECT PropertyAddress, 
	SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1) AS StreetAddress,
	SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress)+1) AS City
FROM nashvillehousingdata; 

ALTER TABLE nashvillehousingdata
ADD PropertyStreetAddress VARCHAR(256);
UPDATE nashvillehousingdata
SET PropertyStreetAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1);

ALTER TABLE nashvillehousingdata
ADD PropertyCity VARCHAR(256);
UPDATE nashvillehousingdata
SET PropertyCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress)+1);

SELECT PropertyAddress, PropertyStreetAddress, PropertyCity
FROM nashvillehousingdata;

-- Secondly deal with the OwnerAddress
SELECT OwnerAddress
FROM nashvillehousingdata; 

SELECT OwnerAddress, 
	SUBSTRING_INDEX(OwnerAddress, ',', 1) AS OwnerAddressStreet, 
    SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) AS OwnerAddressCity, 
	SUBSTRING_INDEX(OwnerAddress, ',', -1) AS OwnerAddressState
FROM nashvillehousingdata; 

ALTER TABLE nashvillehousingdata
ADD OwnerAddressStreet VARCHAR(256);
UPDATE nashvillehousingdata
SET OwnerAddressStreet = SUBSTRING_INDEX(OwnerAddress, ',', 1);

ALTER TABLE nashvillehousingdata
ADD OwnerAddressCity VARCHAR(256);
UPDATE nashvillehousingdata
SET OwnerAddressCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);

ALTER TABLE nashvillehousingdata
ADD OwnerAddressState VARCHAR(256);
UPDATE nashvillehousingdata
SET OwnerAddressState = SUBSTRING_INDEX(OwnerAddress, ',', -1);

SELECT OwnerAddress, OwnerAddressStreet, OwnerAddressCity, OwnerAddressState
FROM nashvillehousingdata;

-- Change Y and N to YES and NO in 'SoldAsVacant' column------------------------------------------------------------------------------------
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM nashvillehousingdata
GROUP BY SoldAsVacant
ORDER BY COUNT(SoldAsVacant);

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
         ELSE SoldAsVacant
	END AS NewSoldAsVacant
FROM nashvillehousingdata;

Update nashvillehousingdata
SET SoldAsVacant = 
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
         ELSE SoldAsVacant
	END;

-- Remove Duplicates--------------------------------------------------------------------------------------------------------------------
SELECT *, ROW_NUMBER() OVER (
	PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
    ORDER BY UniqueID)
FROM nashvillehousingdata;  -- We can't use window function in the where clause. So here we use CTE to temporarily store the query consequence.

WITH DuplicateNumber AS(
	SELECT *, ROW_NUMBER() OVER (
		PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
		ORDER BY UniqueID) AS RowNumber
	FROM nashvillehousingdata
)
SELECT * 
FROM DuplicateNumber
WHERE RowNumber <>1;  -- 104 duplicates. We can't delete directly from CTE table. So we delete duplicates like below:

WITH DuplicateNumber AS (
    SELECT 
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
            ORDER BY UniqueID
        ) AS RowNumber,
        UniqueID
    FROM nashvillehousingdata
)
DELETE nhd
FROM nashvillehousingdata nhd
JOIN DuplicateNumber dn
    ON nhd.UniqueID = dn.UniqueID
WHERE dn.RowNumber > 1;

-- Delete Unused Columns------------------------------------------------------------------------------------------------------
SELECT *
FROM nashvillehousingdata;

ALTER TABLE nashvillehousingdata
DROP COLUMN PropertyAddress, 
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict;