using { earmms.sf as sf } from '../db/schema';

@path: '/odata/v4/masterdata'
service MasterDataService {
  @readonly entity Employee       as projection on sf.Employee;
  @readonly entity Asset          as projection on sf.Asset;
  @readonly entity AssetType      as projection on sf.AssetType;
  @readonly entity Technician     as projection on sf.Technician;
  @readonly entity SpareAssetPool as projection on sf.SpareAssetPool;
}
