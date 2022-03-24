-- STANDARDIZE SaleDate FORMAT
	--Removing time at the end of SaleDate (converting from datetime to date)

	--Run Once to update table with new columns:
		--ALTER TABLE NashvilleHousing
		--ADD SaleDateConverted Date;

		--UPDATE NashvilleHousing
		--SET SaleDateConverted = CONVERT(Date,SaleDate)

	SELECT SaleDate, SaleDateConverted
	FROM NashvilleHousing

-- ADDRESS NULLS IN PropertyAddress
	--Select NULLS in PropertyAddress
	SELECT *
	FROM NVHouseExploration..NashvilleHousing
	WHERE PropertyAddress IS NULL
		--There are NULL PropertyAddress rows, and need a strategy to input addresses if possible

	--Exploration of related data
	SELECT *
	FROM NVHouseExploration..NashvilleHousing
	ORDER BY ParcelID
		--Found that there is a many-to-1 relationship of ParcelIDs to PropertyAddress
		--Now can update NULL PropertyAddress rows that have a corresponding ParcelID with a Non-NULL PropertyAddress rows

	--Find NULL PropertyAddress fields and what the data the field should have based on ParcelID 
	SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
	FROM NVHouseExploration..NashvilleHousing a
	JOIN NVHouseExploration..NashvilleHousing b
		ON a.ParcelID = b.ParcelID
		AND a.UniqueID <> b.UniqueID
	WHERE a.PropertyAddress IS NULL
		--The query joins the table on itself, in order to find NULL PropertyAdresss rows by Parcel ID
		--The ISNULL function shows a successful match of Property Address from an existing matched ParcelID to a NULL PropertyAddress row

	--Use UPDATE to actually change the PropertyAddress row values inline
	UPDATE a
	SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
	FROM NVHouseExploration..NashvilleHousing a
	JOIN NVHouseExploration..NashvilleHousing b
		ON a.ParcelID = b.ParcelID
		AND a.UniqueID <> b.UniqueID
	WHERE a.PropertyAddress IS NULL

	--Check for NULL on Property Address
	SELECT *
	FROM NVHouseExploration..NashvilleHousing
	WHERE PropertyAddress IS NULL
	--All NULLS have been addressed and corrected!


-- BREAK PropertyAddress INTO INDIVIDUAL COLUMNS (Address, City)

	--View
	SELECT PropertyAddress
	FROM NVHouseExploration..NashvilleHousing
	--Notice that a comma can be used as a delimiter

	--Using SUBSTRING to remove the 2nd element: Address
	SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address
	FROM NVHouseExploration..NashvilleHousing

	--Using SUBSTRING to select the 1st element: City
	SELECT
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, (LEN(PropertyAddress) - CHARINDEX(',', PropertyAddress) -1)) as City
	FROM NVHouseExploration..NashvilleHousing

		--Run Once to update table with new columns:
		--ALTER TABLE NashvilleHousing
		--ADD PropertySplitAddress nvarchar(255);
		--UPDATE NashvilleHousing
		--SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

		--ALTER TABLE NashvilleHousing
		--ADD PropertySplitCity nvarchar(255);
		--UPDATE NashvilleHousing
		--SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, (LEN(PropertyAddress) - CHARINDEX(',', PropertyAddress) -1))

	--Check that new fields have been added correctly
	SELECT PropertyAddress, PropertySplitCity, PropertySplitAddress
	FROM NVHouseExploration..NashvilleHousing


-- BREAK OwnerAddress INTO INDIVIDUAL COLUMNS (Address, City, State)
	
	--View
	SELECT OwnerAddress
	FROM NVHouseExploration..NashvilleHousing

	--Will use the PARSENAME function this time
	SELECT
	PARSENAME(REPLACE(OwnerAddress,',','.'),3)
	,PARSENAME(REPLACE(OwnerAddress,',','.'),2)
	,PARSENAME(REPLACE(OwnerAddress,',','.'),1)
	FROM NVHouseExploration..NashvilleHousing
	--PARSENAME requires period as a delimiter, so we convert the existing comma into a period, and then proceed to use PARSENAME

		--Run Once to update table with new columns:
		--ALTER TABLE NashvilleHousing
		--ADD OwnerSplitAddress nvarchar(255);
		--ALTER TABLE NashvilleHousing
		--ADD OwnerSplitCity nvarchar(255);
		--ALTER TABLE NashvilleHousing
		--ADD OwnerSplitState nvarchar(255);

		--UPDATE NashvilleHousing
		--SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)
		--UPDATE NashvilleHousing
		--SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)
		--UPDATE NashvilleHousing
		--SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

		--Check
		SELECT TOP(15) *
		FROM NVHouseExploration..NashvilleHousing

--STANDARDIZE SoldAsVacant
	--Currently has Y,N,Yes,No, need just 2 options.
	SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) as COUNTS
	FROM NVHouseExploration..NashvilleHousing
	GROUP BY SoldAsVacant
	ORDER BY 2
	--We will rectify to have only Yes and No

	--Will use CASE statements to fix
	SELECT SoldAsVacant
	, CASE	WHEN SoldAsVacant = 'Y' THEN 'Yes'
			WHEN SoldAsVacant = 'N' THEN 'No'
			ELSE SoldAsVacant
			END
	FROM NVHouseExploration..NashvilleHousing

		--Run Once to update table with new columns:
		--UPDATE NashvilleHousing
		--SET SoldAsVacant = 
		--CASE	WHEN SoldAsVacant = 'Y' THEN 'Yes'
		--		WHEN SoldAsVacant = 'N' THEN 'No'
		--		ELSE SoldAsVacant
		--		END

	--Check
	SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) as COUNTS
	FROM NVHouseExploration..NashvilleHousing
	GROUP BY SoldAsVacant
	ORDER BY 2

--REMOVE DUPLICATES
	--As defined by the following fields in the PARTITION BY being equal
	WITH RowNumCTE as(
		SELECT *,
			ROW_NUMBER() OVER (
			PARTITION BY	ParcelID,
							PropertyAddress,
							SalePrice,
							SaleDate,
							LegalReference
							ORDER BY
								UniqueID
								) row_num
		FROM NVHouseExploration..NashvilleHousing
	)
	SELECT *
	FROM RowNumCTE
	WHERE row_num > 1


		--Run Once to delete duplicates:
		--WITH RowNumCTE as(
		--	SELECT *,
		--		ROW_NUMBER() OVER (
		--		PARTITION BY	ParcelID,
		--						PropertyAddress,
		--						SalePrice,
		--						SaleDate,
		--						LegalReference
		--						ORDER BY
		--							UniqueID
		--							) row_num
		--	FROM NVHouseExploration..NashvilleHousing
		--)
		--DELETE
		--FROM RowNumCTE
		--WHERE row_num > 1

	--Check
		WITH RowNumCTE as(
			SELECT *,
				ROW_NUMBER() OVER (
				PARTITION BY	ParcelID,
								PropertyAddress,
								SalePrice,
								SaleDate,
								LegalReference
								ORDER BY
									UniqueID
									) row_num
			FROM NVHouseExploration..NashvilleHousing
		)
		SELECT *
		FROM RowNumCTE
		WHERE row_num > 1

--DELETE UNUSED COLUMNS
	--Can delete original columns, instead keeping our split columns for address

	--View
	SELECT *
	FROM NVHouseExploration..NashvilleHousing

	--Run Once to DROP unwanted columns
	--ALTER TABLE NVHouseExploration..NashvilleHousing
	--DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

