/*

SQL Cleaning Data

*/


SELECT *
	FROM PortfolioProject.dbo.NashvilleHousingMarket

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format
-- Remove time, which serves no purpose

ALTER TABLE PortfolioProject..NashvilleHousingMarket
	ADD convertedSaleDate Date;

UPDATE PortfolioProject..NashvilleHousingMarket
	SET convertedSaleDate = CONVERT(Date, SaleDate)

SELECT SaleDate, convertedSaleDate
	FROM PortfolioProject..NashvilleHousingMarket

 --------------------------------------------------------------------------------------------------------------------------

-- Populate PropertyAddress data

SELECT PropertyAddress
	FROM PortfolioProject..NashvilleHousingMarket
	WHERE PropertyAddress IS NULL
	order by ParcelID

SELECT *
	FROM PortfolioProject..NashvilleHousingMarket
	order by ParcelID

-- Perform a self join to populate PropertyAddress

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
	FROM PortfolioProject..NashvilleHousingMarket a
	JOIN PortfolioProject..NashvilleHousingMarket b
		ON a.ParcelID = b.ParcelID
		AND a.[UniqueID ] <> b.[UniqueID ]
	WHERE a.PropertyAddress IS NULL

UPDATE a
	SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
		FROM PortfolioProject..NashvilleHousingMarket a
		JOIN PortfolioProject..NashvilleHousingMarket b
			ON a.ParcelID = b.ParcelID
			AND a.[UniqueID ] <> b.[UniqueID ]

--------------------------------------------------------------------------------------------------------------------------

-- Breaking out PropertyAddress into Individual Columns (Address, City, State)

SELECT PropertyAddress
	FROM PortfolioProject..NashvilleHousingMarket

SELECT
	PropertyAddress,
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) 'Address',
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) 'City'
		FROM PortfolioProject..NashvilleHousingMarket

ALTER TABLE PortfolioProject..NashvilleHousingMarket
	ADD PropertyAddress2 nvarchar(255);

UPDATE PortfolioProject..NashvilleHousingMarket
	SET PropertyAddress2 = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE PortfolioProject..NashvilleHousingMarket
	ADD City nvarchar(255);

UPDATE PortfolioProject..NashvilleHousingMarket
	SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

-- Breaking out OwnerAddress into Individual Columns (Address, City, State)

SELECT OwnerAddress
	FROM PortfolioProject..NashvilleHousingMarket

SELECT
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
		FROM PortfolioProject..NashvilleHousingMarket

ALTER TABLE PortfolioProject..NashvilleHousingMarket
	ADD OwnerAddress2 nvarchar(255);

UPDATE PortfolioProject..NashvilleHousingMarket
	SET OwnerAddress2 = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE PortfolioProject..NashvilleHousingMarket
	ADD OwnerCity nvarchar(255);

UPDATE PortfolioProject..NashvilleHousingMarket
	SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE PortfolioProject..NashvilleHousingMarket
	ADD OwnerState nvarchar(255);

UPDATE PortfolioProject..NashvilleHousingMarket
	SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

--------------------------------------------------------------------------------------------------------------------------

-- Change Y/N to Yes/No in SoldAsVacant column using case statements

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
	FROM PortfolioProject..NashvilleHousingMarket
	GROUP BY SoldAsVacant
	ORDER BY 2

SELECT SoldAsVacant,
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END
	FROM PortfolioProject..NashvilleHousingMarket
	ORDER BY 1

UPDATE PortfolioProject..NashvilleHousingMarket
	SET SoldAsVacant = CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END

-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS(
	SELECT *, ROW_NUMBER() OVER (
		PARTITION BY	ParcelID,
						PropertyAddress,
						SalePrice,
						SaleDate,
						LegalReference
						ORDER BY UniqueID) row_num
		FROM PortfolioProject..NashvilleHousingMarket
) DELETE
	FROM RowNumCTE
	WHERE row_num > 1

---------------------------------------------------------------------------------------------------------

-- Delete unused and outdated columns

SELECT *
	FROM PortfolioProject..NashvilleHousingMarket

ALTER TABLE PortfolioProject..NashvilleHousingMarket
	DROP COLUMN PropertyAddress, SaleDate, OwnerAddress

