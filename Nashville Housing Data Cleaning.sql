/*

Cleaning Data Set NashHousing

*/

select * 
from NashHousing


-- 1. Standadizing the SaleDate

select SaleDate, convert(date,SaleDate) as Date
from NashHousing

alter table NashHousing
add SaleDateConverted date;

update NashHousing
set SaleDateConverted = convert(date,SaleDate)

select SaleDateConverted
from NashHousing



-- 2. Populating Nulls in Property Address

Select A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress)
from NashHousing as A
Join NashHousing as B
	on A.ParcelID = B.ParcelID
	and A.[UniqueID ]<>B.[UniqueID ]
where A.PropertyAddress is null

update A
set PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
from NashHousing as A
Join NashHousing as B
	on A.ParcelID = B.ParcelID
	and A.[UniqueID ]<>B.[UniqueID ]
where A.PropertyAddress is null

--checking for nulls
Select *
from NashHousing
where PropertyAddress is null


-- 3. Splitting PropertyAddress to Street Name and City Columns	

Select PropertyAddress
from NashHousing
/*

Testing out how to access ',' delimiter using substrings

Select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, len(PropertyAddress)) as PropertyAddressCity
from NashHousing
*/

Alter table NashHousing
Add PropertyAddressStreet nvarchar(255),
PropertyAddressCity nvarchar(255);

Update NashHousing
Set PropertyAddressStreet = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)
, PropertyAddressCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, len(PropertyAddress))


-- 4. Splitting OwnerAddress to Street Name, City, St Columns
Select OwnerAddress
from NashHousing

/*Utilizing Parse

select
ParseName(Replace(OwnerAddress, ',' ,'.'),3) as OwnerAddressStreet
,ParseName(Replace(OwnerAddress, ',' ,'.'),2) as OwnerAddressCity
,ParseName(Replace(OwnerAddress, ',' ,'.'),1) as OwnerAddressState
from NashHousing

*/

Alter table NashHousing
Add OwnerAddressStreet nvarchar(255),
OwnerAddressCity nvarchar(255),
OwnerAddressState nvarchar(255);

Update NashHousing
Set OwnerAddressStreet = ParseName(Replace(OwnerAddress, ',' ,'.'),3),
OwnerAddressCity = ParseName(Replace(OwnerAddress, ',' ,'.'),2),
OwnerAddressState = ParseName(Replace(OwnerAddress, ',' ,'.'),1)


-- 5. Cleaning up SoldasVacant to 'Yes' and 'No' only

Update NashHousing
set SoldAsVacant = Case when SoldAsVacant = 'Y' Then 'Yes'
	   when SoldAsVacant = 'N' Then 'No'
	   else SoldAsVacant
	   end

Select Distinct(SoldasVacant), count(SoldasVacant)
from NashHousing
Group by SoldAsVacant
order by 2 


-- 6. Removing Duplicates 

--creating a CTE identifying duplicates using Partition by
with rowNumCTE as(
select *,
	ROW_NUMBER() Over (
	Partition by ParcelID, PropertyAddress, SaleDate, LegalReference
	Order by UniqueID
	) Row_num
				 
from NashHousing
)

/*
-- Selecting only duplicates

Select *
from rowNumCTE
where Row_num > 1
order by ParcelID


--Delete function for duplicates
Delete
from rowNumCTE
where Row_num > 1

*/


-- 7. Deleting unused Columns

Select *
from NashHousing

Alter table NashHousing
Drop Column SaleDate, PropertyAddress, OwnerAddress, TaxDistrict

--For future best Practices, it would be better to create views that omit 
--unwanted columns rather than deleting columns straight from raw data