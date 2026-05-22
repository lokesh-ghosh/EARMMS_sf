namespace earmms.sf;

entity AssetType {
  key typeId           : String(20);
      typeName         : String(100);
      category         : String(20);   // IT | FURNITURE | ELECTRONICS
      isCritical       : Boolean;
      standardSLAHours : Integer;
}

entity Employee {
  key employeeId         : String(20);
      name               : String(100);
      email              : String(100);
      department         : String(50);
      designation        : String(50);
      manager_employeeId : String(20);
      isVIP              : Boolean;
}

entity Asset {
  key assetId        : UUID;
      assetTag       : String(20);
      assetType      : Association to AssetType;
      make           : String(50);
      model          : String(50);
      serialNumber   : String(50);
      purchaseDate   : Date;
      warrantyExpiry : Date;
      currentOwner   : Association to Employee;
      location       : String(100);
      status         : String(20);   // Active | UnderRepair | InMitigation | Retired
}

entity Technician {
  key technicianId   : UUID;
      name           : String(100);
      email          : String(100);
      specialization : String(50);   // Laptop | Networking | Furniture
      currentLoad    : Integer;
}

entity SpareAssetPool {
  key poolId                   : UUID;
      asset                    : Association to Asset;
      availabilityStatus       : String(20);   // Available | Reserved | InUse
      reservedFor_mitigationId : UUID;
}

entity SLAConfiguration {
  key configId            : UUID;
      assetType           : Association to AssetType;
      severity            : String(10);   // Low | Medium | High
      responseTimeHours   : Integer;
      resolutionTimeHours : Integer;
      mitigationSLAHours  : Integer;
}
