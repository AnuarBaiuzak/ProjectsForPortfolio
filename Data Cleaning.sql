/*

Запросы SQL для очистки данных

*/

select *
from PortfolioProject..DataForCleaning


-- Стандартизация формата даты

select SaleDateConverted, CONVERT(date, SaleDate)
from PortfolioProject..DataForCleaning

update DataForCleaning
set SaleDate=CONVERT(date, SaleDate)

alter table DataForCleaning
add SaleDateConverted Date;

update DataForCleaning
set SaleDateConverted=CONVERT(date, SaleDate)


-- Заполнение пустых адресов

select *
from PortfolioProject..DataForCleaning
--where PropertyAddress is null
order by ParcelID


select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, isnull(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject..DataForCleaning a
join PortfolioProject..DataForCleaning b
	on a.ParcelID=b.ParcelID
	and a.[UniqueID ]<>b.[UniqueID ]
where a.PropertyAddress is null

update a
set PropertyAddress=isnull(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject..DataForCleaning a
join PortfolioProject..DataForCleaning b
	on a.ParcelID=b.ParcelID
	and a.[UniqueID ]<>b.[UniqueID ]
where a.PropertyAddress is null


-- Разделение адресов по разным столбцам (адрес, город, штат)

select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address
from PortfolioProject..DataForCleaning


alter table PortfolioProject..DataForCleaning
add PropertySplitAddress Nvarchar(255);

update PortfolioProject..DataForCleaning
set PropertySplitAddress=SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)


alter table PortfolioProject..DataForCleaning
add PropertySplitCity Nvarchar(255);

update PortfolioProject..DataForCleaning
set PropertySplitCity=SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


select
PARSENAME(replace(OwnerAddress, ',', '.'), 3),
PARSENAME(replace(OwnerAddress, ',', '.'), 2),
PARSENAME(replace(OwnerAddress, ',', '.'), 1)
from PortfolioProject..DataForCleaning

alter table PortfolioProject..DataForCleaning
add OwnerSplitAddress Nvarchar(255);

update PortfolioProject..DataForCleaning
set OwnerSplitAddress=PARSENAME(replace(OwnerAddress, ',', '.'), 3)

alter table PortfolioProject..DataForCleaning
add OwnerSplitCity Nvarchar(255);

update PortfolioProject..DataForCleaning
set OwnerSplitCity=PARSENAME(replace(OwnerAddress, ',', '.'), 2)

alter table PortfolioProject..DataForCleaning
add OwnerSplitState Nvarchar(255);

update PortfolioProject..DataForCleaning
set OwnerSplitState=PARSENAME(replace(OwnerAddress, ',', '.'), 1)


-- Изменить 'Y' и 'N' на 'Yes' и 'No'

select SoldAsVacant,
case when SoldAsVacant = 'Y' then 'Yes'
	 when SoldAsVacant = 'N' then 'NO'
	 else SoldAsVacant
	 end
from PortfolioProject..DataForCleaning

update PortfolioProject..DataForCleaning
set SoldAsVacant=case when SoldAsVacant = 'Y' then 'Yes'
	 when SoldAsVacant = 'N' then 'NO'
	 else SoldAsVacant
	 end


-- Удаление дупликатов

with RowNumCTE as
(
select *,
	ROW_NUMBER() over (
	partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 order by UniqueID
				 ) row_num
from PortfolioProject..DataForCleaning
)
delete
from RowNumCTE
where row_num > 1


-- Удаление неиспользуемых столбцов

alter table PortfolioProject..DataForCleaning
drop column PropertyAddress, OwnerAddress, TaxDistrict