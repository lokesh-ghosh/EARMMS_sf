# EARMMS Master Data Service — API Documentation

**For:** EARMMS CAP (main application) team  
**Base URL (local):** `http://localhost:4004/odata/v4/masterdata`  
**Base URL (CF):** `https://<cf-route>/odata/v4/masterdata`  
**Protocol:** OData V4  
**Content-Type:** `application/json`

---

## 1. Overview

This service is the **single source of truth** for EARMMS master data. The main EARMMS CAP application must:
- **Read** employees, assets, technicians, spare pool, and SLA config from here
- **PATCH** asset status, technician load, and spare pool status back here when business events occur
- **Never** duplicate master data locally

### OData Conventions
- List: `GET /Entity`
- Single: `GET /Entity(<key>)`
- Create: `POST /Entity`
- Update: `PATCH /Entity(<key>)`
- Delete: `DELETE /Entity(<key>)`
- Expand: `?$expand=associationName`
- Filter: `?$filter=field eq 'value'`
- Select: `?$select=field1,field2`

---

## 2. Entities & Fields

### Employee
| Field | Type | Notes |
|-------|------|-------|
| employeeId | String(20) | **PK** — from SuccessFactors |
| name | String(100) | |
| email | String(100) | |
| department | String(50) | |
| designation | String(50) | |
| manager_employeeId | String(20) | FK self-reference |
| isVIP | Boolean | VIP employees get priority handling |

### AssetType
| Field | Type | Notes |
|-------|------|-------|
| typeId | String(20) | **PK** — e.g., LAPTOP, MONITOR, CHAIR |
| typeName | String(100) | |
| category | String(20) | `IT` \| `FURNITURE` \| `ELECTRONICS` |
| isCritical | Boolean | |
| standardSLAHours | Integer | Default SLA fallback |

### Asset
| Field | Type | Notes |
|-------|------|-------|
| assetId | UUID | **PK** |
| assetTag | String(20) | e.g., LAP-2026-0451 |
| assetType_typeId | String(20) | FK → AssetType |
| make | String(50) | |
| model | String(50) | |
| serialNumber | String(50) | |
| purchaseDate | Date | |
| warrantyExpiry | Date | |
| currentOwner_employeeId | String(20) | FK → Employee |
| location | String(100) | |
| status | String(20) | `Active` \| `UnderRepair` \| `InMitigation` \| `Retired` |

### Technician
| Field | Type | Notes |
|-------|------|-------|
| technicianId | UUID | **PK** |
| name | String(100) | |
| email | String(100) | |
| specialization | String(50) | `Laptop` \| `Networking` \| `Furniture` |
| currentLoad | Integer | Active ticket count — updated by main app |

### SpareAssetPool
| Field | Type | Notes |
|-------|------|-------|
| poolId | UUID | **PK** |
| asset_assetId | UUID | FK → Asset |
| availabilityStatus | String(20) | `Available` \| `Reserved` \| `InUse` |
| reservedFor_mitigationId | UUID | ID of linked MitigationRequest (cross-app, no FK enforced) |

### SLAConfiguration
| Field | Type | Notes |
|-------|------|-------|
| configId | UUID | **PK** |
| assetType_typeId | String(20) | FK → AssetType |
| severity | String(10) | `Low` \| `Medium` \| `High` |
| responseTimeHours | Integer | Max hours to first response |
| resolutionTimeHours | Integer | Max hours to resolution |
| mitigationSLAHours | Integer | Max hours to issue replacement |

---

## 3. Endpoints

---

### Employee

#### GET /Employee — List all employees
```
GET /odata/v4/masterdata/Employee

Response 200:
{
  "value": [
    {
      "employeeId": "E001",
      "name": "Arjun Mehta",
      "email": "arjun.mehta@company.com",
      "department": "IT",
      "designation": "Senior Manager",
      "manager_employeeId": null,
      "isVIP": true
    }
  ]
}
```

#### GET /Employee('E001') — Single employee
```
GET /odata/v4/masterdata/Employee('E001')

Response 200:
{
  "employeeId": "E001",
  "name": "Arjun Mehta",
  ...
}
```

#### POST /Employee — Create employee (used by CPI sync)
```
POST /odata/v4/masterdata/Employee
Content-Type: application/json

{
  "employeeId": "E006",
  "name": "Ravi Pillai",
  "email": "ravi.pillai@company.com",
  "department": "Operations",
  "designation": "Operations Lead",
  "manager_employeeId": "E001",
  "isVIP": false
}

Response 201 Created
```

#### PATCH /Employee('E006') — Update employee
```
PATCH /odata/v4/masterdata/Employee('E006')
Content-Type: application/json

{ "designation": "Senior Operations Lead" }

Response 200 OK
```

---

### Asset

#### GET /Asset — List all assets
```
GET /odata/v4/masterdata/Asset
GET /odata/v4/masterdata/Asset?$expand=assetType,currentOwner
GET /odata/v4/masterdata/Asset?$filter=status eq 'Active'
GET /odata/v4/masterdata/Asset?$filter=currentOwner_employeeId eq 'E002'
```

#### PATCH /Asset — Update asset status (called by main app on RR/MR events)
```
PATCH /odata/v4/masterdata/Asset(assetId=d4e5f6a7-b8c9-0123-defa-123456789001)
Content-Type: application/json

{ "status": "UnderRepair" }

Response 200 OK

Allowed status values: Active | UnderRepair | InMitigation | Retired
```

**When to call:**
| Event | status value |
|-------|-------------|
| RR created / technician assigned | `UnderRepair` |
| MR issued (replacement given) | `InMitigation` |
| RR closed / asset returned | `Active` |
| Asset decommissioned | `Retired` |

---

### Technician

#### GET /Technician — List all technicians
```
GET /odata/v4/masterdata/Technician
GET /odata/v4/masterdata/Technician?$orderby=currentLoad asc
GET /odata/v4/masterdata/Technician?$filter=specialization eq 'Laptop'
```

#### PATCH /Technician — Update currentLoad (called by main app on ticket assign/close)
```
PATCH /odata/v4/masterdata/Technician(technicianId=a1b2c3d4-e5f6-7890-abcd-ef1234567890)
Content-Type: application/json

{ "currentLoad": 3 }

Response 200 OK
```

**BPA usage:** To find the lowest-load technician with matching specialization:
```
GET /odata/v4/masterdata/Technician
  ?$filter=specialization eq 'Laptop'
  &$orderby=currentLoad asc
  &$top=1
```

---

### SpareAssetPool

#### GET /SpareAssetPool — List spare assets
```
GET /odata/v4/masterdata/SpareAssetPool
GET /odata/v4/masterdata/SpareAssetPool?$expand=asset
GET /odata/v4/masterdata/SpareAssetPool?$filter=availabilityStatus eq 'Available'
```

#### PATCH /SpareAssetPool — Reserve or release a spare (called by main app on MR issue/return)

**Issue replacement (MR approved):**
```
PATCH /odata/v4/masterdata/SpareAssetPool(poolId=e5f6a7b8-c9d0-1234-efab-234567890001)
Content-Type: application/json

{
  "availabilityStatus": "Reserved",
  "reservedFor_mitigationId": "<<mitigationId UUID from main app>>"
}

Response 200 OK
```

**Return replacement (MR closed):**
```
PATCH /odata/v4/masterdata/SpareAssetPool(poolId=e5f6a7b8-c9d0-1234-efab-234567890001)
Content-Type: application/json

{
  "availabilityStatus": "Available",
  "reservedFor_mitigationId": null
}

Response 200 OK
```

---

### SLAConfiguration

#### GET /SLAConfiguration — Lookup SLA rules (called by main app on RR creation)
```
GET /odata/v4/masterdata/SLAConfiguration
  ?$filter=assetType_typeId eq 'LAPTOP' and severity eq 'High'
  &$expand=assetType

Response 200:
{
  "value": [
    {
      "configId": "f6a7b8c9-d0e1-2345-fabc-345678901003",
      "assetType_typeId": "LAPTOP",
      "severity": "High",
      "responseTimeHours": 1,
      "resolutionTimeHours": 4,
      "mitigationSLAHours": 8
    }
  ]
}
```

**How to compute expectedResolution in main app:**
```js
const sla = await GET SLAConfiguration filtered by assetType + severity
const expectedResolution = new Date(raisedOn.getTime() + sla.resolutionTimeHours * 3600000)
```

---

### AssetType

#### GET /AssetType — List asset types (read-only reference data)
```
GET /odata/v4/masterdata/AssetType

Response 200:
{
  "value": [
    { "typeId": "LAPTOP", "typeName": "Laptop Computer", "category": "IT", "isCritical": true, "standardSLAHours": 8 },
    { "typeId": "MONITOR", "typeName": "Monitor / Display", "category": "IT", "isCritical": false, "standardSLAHours": 24 },
    { "typeId": "DESKTOP", "typeName": "Desktop Computer", "category": "IT", "isCritical": true, "standardSLAHours": 12 },
    { "typeId": "CHAIR", "typeName": "Office Chair", "category": "FURNITURE", "isCritical": false, "standardSLAHours": 72 },
    { "typeId": "PROJECTOR", "typeName": "Projector", "category": "ELECTRONICS", "isCritical": false, "standardSLAHours": 48 }
  ]
}
```

---

## 4. Integration Guide for Main EARMMS CAP App

### Connecting to this service

In main app's `.cdsrc.json`:
```json
{
  "requires": {
    "MasterDataService": {
      "kind": "odata-v4",
      "credentials": { "url": "https://<cf-route>/odata/v4/masterdata" }
    }
  }
}
```

### Event → PATCH mapping

| EARMMS Event | This service call |
|---|---|
| RR created | PATCH `Asset` → `status = UnderRepair` |
| Technician assigned | PATCH `Technician` → `currentLoad = currentLoad + 1` |
| RR resolved / closed | PATCH `Technician` → `currentLoad = currentLoad - 1`; PATCH `Asset` → `status = Active` |
| MR approved + spare issued | PATCH `SpareAssetPool` → `availabilityStatus = Reserved`, set `reservedFor_mitigationId`; PATCH `Asset` (replacement) → `status = InMitigation` |
| Spare returned | PATCH `SpareAssetPool` → `availabilityStatus = Available`, clear `reservedFor_mitigationId`; PATCH `Asset` (replacement) → `status = Active` |

---

## 5. Error Codes

| HTTP Status | Meaning |
|-------------|---------|
| 200 OK | Successful GET or PATCH |
| 201 Created | Successful POST |
| 400 Bad Request | Malformed request body or missing required fields |
| 404 Not Found | Entity with given key does not exist |
| 405 Method Not Allowed | Not applicable here (all CRUD is open) |
| 500 Internal Server Error | Server-side error — check CAP logs |

OData error response format:
```json
{
  "error": {
    "code": "404",
    "message": "Entity 'Employee' with key 'E999' not found"
  }
}
```

---

## 6. Seeded Mock Data Summary

| Entity | Count | Key values |
|--------|-------|-----------|
| AssetType | 5 | LAPTOP, MONITOR, DESKTOP, CHAIR, PROJECTOR |
| Employee | 5 | E001–E005 (E001 is VIP manager) |
| Technician | 3 | Laptop / Networking / Furniture specialists |
| Asset | 10 | Mix of types; LAP-2026-0004 and LAP-2026-0005 are unassigned spares |
| SpareAssetPool | 5 | All `Available` at startup |
| SLAConfiguration | 15 | All 5 asset types × Low/Medium/High severity |
