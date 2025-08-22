# SMT工厂生产数据管理数据库设计

## 概述

这是一个专为SMT（表面贴装技术）工厂设计的生产数据管理系统数据库结构，特别适用于手机主板等电子产品的生产管理。该系统能够追踪每块主板上每个物料的完整生命周期，从BOM设计到生产完成的全过程。

## 手机主板物料数量

根据行业数据，一个典型的手机主板上通常包含：

- **被动元件**：800-1200个（电阻、电容、电感等）
- **主动元件**：50-100个（IC芯片、晶体管等）
- **连接器**：20-50个
- **其他元件**：100-200个

**总计：约1000-1500个物料**

## 核心设计理念

### 1. 单板级追踪
- 每块主板都有唯一的`board_id`
- 每个物料在每块主板上都有详细的使用记录
- 支持完整的生产追溯链

### 2. 物料生命周期管理
- 从供应商到生产线的完整物料流
- 批次管理和质量追溯
- 库存实时监控和预警

### 3. 生产过程控制
- 工单管理和进度跟踪
- 批次生产和质量控制
- 设备状态和维护管理

## 数据库表结构

### 基础主数据表
- `product_models` - 产品型号表
- `materials` - 物料主数据表
- `suppliers` - 供应商表
- `production_lines` - 生产线表
- `employees` - 员工表

### BOM管理表
- `product_boms` - 产品BOM主表
- `bom_details` - BOM明细表

### 生产管理表
- `production_orders` - 生产工单表
- `production_batches` - 生产批次表
- `board_production_records` - 单板生产记录表（核心表）
- `board_material_usage` - 单板物料使用记录表

### 质量管理表
- `inspection_items` - 检测项目表
- `board_inspection_records` - 单板检测记录表

### 库存管理表
- `inventory` - 库存表
- `inventory_transactions` - 库存事务表

### 设备管理表
- `machines` - 设备表
- `machine_maintenance` - 设备维护记录表

## 关键特性

### 1. 唯一标识系统
```sql
-- 每块主板唯一ID
board_id VARCHAR(100) PRIMARY KEY

-- 每个物料在每块主板上的使用记录
board_material_usage (board_id, material_id, position_ref)
```

### 2. 位置追踪
```sql
-- PCB坐标和位置信息
x_coordinate DECIMAL(10,2), -- X坐标
y_coordinate DECIMAL(10,2), -- Y坐标
layer VARCHAR(20), -- 层（TOP/BOTTOM）
rotation_angle DECIMAL(5,2), -- 旋转角度
position_ref VARCHAR(100) -- 位置参考（R1, C2, U1等）
```

### 3. 批次管理
```sql
-- 物料批次追踪
lot_number VARCHAR(100), -- 批次号
supplier_batch VARCHAR(100), -- 供应商批次
```

### 4. 质量分级
```sql
-- 产品质量分级
quality_grade VARCHAR(10), -- A, B, C, REJECT
defect_type VARCHAR(100), -- 缺陷类型
defect_description TEXT -- 缺陷描述
```

## 核心查询示例

### 1. 查询单板物料清单
```sql
SELECT 
    bm.position_ref,
    m.material_name,
    m.part_number,
    bm.quantity_used,
    bm.lot_number,
    bm.installation_time
FROM board_material_usage bm
JOIN materials m ON bm.material_id = m.material_id
WHERE bm.board_id = 'BOARD-001'
ORDER BY bm.position_ref;
```

### 2. 生产良率统计
```sql
SELECT 
    DATE(production_date) as production_date,
    model_id,
    COUNT(*) as total_boards,
    COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) as completed_boards,
    ROUND(
        (COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END)::DECIMAL / COUNT(*)::DECIMAL) * 100, 2
    ) as yield_rate
FROM board_production_records
GROUP BY DATE(production_date), model_id;
```

### 3. 物料库存状态
```sql
SELECT 
    m.material_name,
    m.category,
    COALESCE(SUM(i.quantity_on_hand), 0) as total_stock,
    m.min_stock,
    CASE 
        WHEN COALESCE(SUM(i.quantity_available), 0) <= m.min_stock THEN 'LOW_STOCK'
        ELSE 'NORMAL'
    END as stock_status
FROM materials m
LEFT JOIN inventory i ON m.material_id = i.material_id
GROUP BY m.material_id, m.material_name, m.category, m.min_stock;
```

## 性能优化

### 1. 索引策略
- 为常用查询字段创建复合索引
- 支持范围查询的日期索引
- 外键关联字段索引

### 2. 分区策略
- 按生产日期分区单板生产记录表
- 按物料类别分区物料表
- 按时间分区库存事务表

### 3. 归档策略
- 历史数据定期归档
- 冷热数据分离存储
- 压缩存储减少空间占用

## 扩展功能

### 1. 实时监控
- 生产线状态实时更新
- 库存预警自动通知
- 质量异常实时报警

### 2. 报表分析
- 生产效率分析
- 质量趋势分析
- 成本分析报表

### 3. 移动端支持
- 扫码录入生产数据
- 移动端质量检测
- 现场问题反馈

## 部署建议

### 1. 硬件要求
- 数据库服务器：16GB+ RAM，SSD存储
- 应用服务器：8GB+ RAM
- 网络：千兆以太网

### 2. 软件环境
- 数据库：PostgreSQL 12+
- 应用框架：Spring Boot / Django / FastAPI
- 缓存：Redis
- 消息队列：RabbitMQ / Kafka

### 3. 高可用配置
- 主从复制
- 读写分离
- 自动故障转移
- 定期备份恢复

## 维护和监控

### 1. 日常维护
- 数据库性能监控
- 慢查询分析和优化
- 索引维护和重建
- 统计信息更新

### 2. 数据质量
- 数据完整性检查
- 异常数据清理
- 数据一致性验证
- 定期数据审计

### 3. 安全措施
- 访问权限控制
- 数据加密存储
- 操作日志记录
- 定期安全审计

## 总结

这个数据库设计为SMT工厂提供了一个完整的生产数据管理解决方案，能够：

1. **精确追踪**每块主板上每个物料的使用情况
2. **完整记录**从BOM设计到生产完成的全过程
3. **实时监控**生产进度、库存状态和质量状况
4. **支持追溯**任何质量问题的根本原因分析
5. **提供分析**生产效率和成本优化的数据支持

通过这个系统，工厂可以实现数字化生产管理，提高生产效率，降低生产成本，保证产品质量，满足现代制造业的严格要求。
