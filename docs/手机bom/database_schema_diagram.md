# SMT工厂数据库架构图

## 核心表关系图

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  product_models │    │   product_boms  │    │   bom_details   │
│                 │    │                 │    │                 │
│ model_id (PK)   │◄───┤ model_id (FK)   │◄───┤ bom_id (FK)     │
│ model_name      │    │ bom_id (PK)     │    │ material_id (FK)│
│ product_type    │    │ bom_version     │    │ position_ref    │
│ description     │    │ effective_date  │    │ x_coordinate    │
│ revision        │    │ status          │    │ y_coordinate    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│production_orders│    │production_batches│    │    materials    │
│                 │    │                 │    │                 │
│ order_id (PK)   │◄───┤ order_id (FK)   │    │ material_id(PK)│
│ model_id (FK)   │    │ batch_id (PK)   │    │ material_name  │
│ bom_id (FK)     │    │ batch_number    │    │ category       │
│ quantity_planned│    │ quantity        │    │ part_number    │
│ status          │    │ status          │    │ manufacturer   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                board_production_records                         │
│                                                                 │
│ board_id (PK) ◄─── 每块主板唯一标识                            │
│ batch_id (FK)                                                  │
│ order_id (FK)                                                  │
│ model_id (FK)                                                  │
│ serial_number                                                  │
│ status                                                         │
│ quality_grade                                                  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                board_material_usage                            │
│                                                                 │
│ usage_id (PK)                                                  │
│ board_id (FK) ◄─── 关联到具体主板                             │
│ material_id (FK) ◄─── 关联到具体物料                          │
│ position_ref ◄─── 位置参考(R1,C2,U1等)                        │
│ quantity_used                                                  │
│ lot_number ◄─── 批次号                                         │
│ installation_time                                              │
│ status                                                         │
└─────────────────────────────────────────────────────────────────┘
```

## 数据流向图

```
供应商 → 物料入库 → 库存管理 → 生产领料 → 生产使用 → 质量检测 → 成品入库
  ↓           ↓         ↓         ↓         ↓         ↓         ↓
suppliers  inventory  materials  bom_details  board_material_usage  board_inspection_records
```

## 关键表字段说明

### 1. board_production_records (单板生产记录表 - 核心表)
- `board_id`: 每块主板的唯一标识
- `serial_number`: 序列号
- `pcb_id`: PCB板ID
- `status`: 生产状态
- `quality_grade`: 质量等级

### 2. board_material_usage (单板物料使用记录表 - 核心表)
- `board_id`: 关联到具体主板
- `material_id`: 关联到具体物料
- `position_ref`: 位置参考（如R1, C2, U1等）
- `lot_number`: 物料批次号
- `installation_time`: 安装时间

### 3. materials (物料主数据表)
- `material_id`: 物料唯一标识
- `category`: 物料类别（电阻、电容、IC等）
- `sub_category`: 子类别（0805、0603、QFP等）
- `value_spec`: 规格值（阻值、容值等）

### 4. product_boms (产品BOM表)
- `bom_id`: BOM唯一标识
- `model_id`: 关联产品型号
- `bom_version`: BOM版本
- `effective_date`: 生效日期

## 查询路径示例

### 查询单板完整物料清单
```
board_production_records.board_id 
    ↓
board_material_usage.board_id 
    ↓
materials.material_id
    ↓
bom_details.material_id (获取位置信息)
```

### 查询生产良率
```
board_production_records 
    ↓
按日期、型号分组统计
    ↓
计算完成数量/总数量
```

### 查询物料库存状态
```
materials.material_id 
    ↓
inventory.material_id
    ↓
汇总库存数量
    ↓
与最小/最大库存比较
```

## 索引策略

### 主要索引
1. `board_production_records(board_id)` - 单板查询
2. `board_production_records(production_date, model_id)` - 生产统计
3. `board_material_usage(board_id, material_id)` - 物料使用查询
4. `inventory(material_id, lot_number)` - 库存查询

### 复合索引
1. `(batch_id, order_id, model_id)` - 批次相关查询
2. `(production_date, status, line_id)` - 生产状态查询
3. `(material_id, warehouse_location)` - 库存位置查询

## 分区策略

### 按时间分区
- `board_production_records`: 按月分区
- `board_material_usage`: 按月分区
- `inventory_transactions`: 按月分区

### 按类别分区
- `materials`: 按物料类别分区
- `inventory`: 按物料类别分区

## 性能优化要点

1. **查询优化**: 使用适当的索引和分区
2. **数据归档**: 定期归档历史数据
3. **缓存策略**: 热点数据使用Redis缓存
4. **读写分离**: 主库写，从库读
5. **连接池**: 合理配置数据库连接池大小
