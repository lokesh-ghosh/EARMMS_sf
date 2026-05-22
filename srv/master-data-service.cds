using { earmms.sf as sf } from '../db/schema';

@path: '/odata/v4/masterdata'
service MasterDataService {
  entity Employee         as projection on sf.Employee;
  entity Asset            as projection on sf.Asset;
  entity AssetType        as projection on sf.AssetType;
  entity Technician       as projection on sf.Technician;
  entity SpareAssetPool   as projection on sf.SpareAssetPool;
  entity SLAConfiguration as projection on sf.SLAConfiguration;
}
