-- SMT工厂生产数据管理数据库表结构设计
-- 适用于手机主板等电子产品的生产管理

-- ========================================
-- 1. 基础主数据表
-- ========================================

-- 产品型号表
CREATE TABLE product_models (
    model_id VARCHAR(50) PRIMARY KEY,
    model_name VARCHAR(100) NOT NULL,
    product_type VARCHAR(50) NOT NULL, -- 手机主板、平板主板等
    description TEXT,
    revision VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'ACTIVE' -- ACTIVE, INACTIVE, DISCONTINUED
);

-- 物料主数据表
CREATE TABLE materials (
    material_id VARCHAR(50) PRIMARY KEY,
    material_name VARCHAR(200) NOT NULL,
    part_number VARCHAR(100),
    manufacturer VARCHAR(100),
    category VARCHAR(50) NOT NULL, -- RESISTOR, CAPACITOR, IC, CONNECTOR等
    sub_category VARCHAR(50), -- 0805, 0603, QFP, BGA等
    package_type VARCHAR(50),
    value_spec VARCHAR(100), -- 阻值、容值、型号等
    unit VARCHAR(20), -- pcs, m, kg等
    min_stock DECIMAL(10,2) DEFAULT 0,
    max_stock DECIMAL(10,2),
    lead_time_days INTEGER DEFAULT 7,
    supplier_id VARCHAR(50),
    unit_price DECIMAL(10,4),
    currency VARCHAR(3) DEFAULT 'CNY',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 供应商表
CREATE TABLE suppliers (
    supplier_id VARCHAR(50) PRIMARY KEY,
    supplier_name VARCHAR(200) NOT NULL,
    contact_person VARCHAR(100),
    phone VARCHAR(50),
    email VARCHAR(100),
    address TEXT,
    qualification_level VARCHAR(20), -- A, B, C级供应商
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 生产线表
CREATE TABLE production_lines (
    line_id VARCHAR(50) PRIMARY KEY,
    line_name VARCHAR(100) NOT NULL,
    line_type VARCHAR(50), -- SMT, DIP, TEST等
    capacity_per_hour INTEGER,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================
-- 2. BOM（物料清单）相关表
-- ========================================

-- 产品BOM主表
CREATE TABLE product_boms (
    bom_id VARCHAR(50) PRIMARY KEY,
    model_id VARCHAR(50) NOT NULL,
    bom_version VARCHAR(20) NOT NULL,
    effective_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'DRAFT', -- DRAFT, APPROVED, OBSOLETE
    created_by VARCHAR(50),
    approved_by VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP,
    FOREIGN KEY (model_id) REFERENCES product_models(model_id)
);

-- BOM明细表
CREATE TABLE bom_details (
    bom_detail_id SERIAL PRIMARY KEY,
    bom_id VARCHAR(50) NOT NULL,
    material_id VARCHAR(50) NOT NULL,
    position_ref VARCHAR(100), -- 位置参考（如R1, C2, U1等）
    quantity_per_unit DECIMAL(10,4) NOT NULL DEFAULT 1,
    unit VARCHAR(20) DEFAULT 'pcs',
    x_coordinate DECIMAL(10,2), -- PCB坐标X
    y_coordinate DECIMAL(10,2), -- PCB坐标Y
    layer VARCHAR(20), -- TOP, BOTTOM
    rotation_angle DECIMAL(5,2), -- 旋转角度
    is_optional BOOLEAN DEFAULT FALSE, -- 是否可选件
    notes TEXT,
    FOREIGN KEY (bom_id) REFERENCES product_boms(bom_id),
    FOREIGN KEY (material_id) REFERENCES materials(material_id)
);

-- ========================================
-- 3. 生产工单相关表
-- ========================================

-- 生产工单主表
CREATE TABLE production_orders (
    order_id VARCHAR(50) PRIMARY KEY,
    model_id VARCHAR(50) NOT NULL,
    bom_id VARCHAR(50) NOT NULL,
    order_type VARCHAR(20) NOT NULL, -- PRODUCTION, REPAIR, SAMPLE等
    quantity_planned INTEGER NOT NULL,
    quantity_completed INTEGER DEFAULT 0,
    quantity_defective INTEGER DEFAULT 0,
    priority VARCHAR(20) DEFAULT 'NORMAL', -- HIGH, NORMAL, LOW
    status VARCHAR(20) DEFAULT 'PLANNED', -- PLANNED, IN_PROGRESS, COMPLETED, CANCELLED
    planned_start_date DATE,
    planned_end_date DATE,
    actual_start_date TIMESTAMP,
    actual_end_date TIMESTAMP,
    line_id VARCHAR(50),
    created_by VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (model_id) REFERENCES product_models(model_id),
    FOREIGN KEY (bom_id) REFERENCES product_boms(bom_id),
    FOREIGN KEY (line_id) REFERENCES production_lines(line_id)
);

-- 工单物料需求表
CREATE TABLE order_material_requirements (
    requirement_id SERIAL PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    material_id VARCHAR(50) NOT NULL,
    required_quantity DECIMAL(10,4) NOT NULL,
    issued_quantity DECIMAL(10,4) DEFAULT 0,
    consumed_quantity DECIMAL(10,4) DEFAULT 0,
    unit VARCHAR(20) DEFAULT 'pcs',
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, ISSUED, CONSUMED
    FOREIGN KEY (order_id) REFERENCES production_orders(order_id),
    FOREIGN KEY (material_id) REFERENCES materials(material_id)
);

-- ========================================
-- 4. 生产执行相关表
-- ========================================

-- 生产批次表
CREATE TABLE production_batches (
    batch_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    batch_number VARCHAR(50) NOT NULL,
    quantity INTEGER NOT NULL,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    status VARCHAR(20) DEFAULT 'IN_PROGRESS', -- IN_PROGRESS, COMPLETED, PAUSED
    operator_id VARCHAR(50),
    line_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES production_orders(order_id),
    FOREIGN KEY (line_id) REFERENCES production_lines(line_id)
);

-- 单板生产记录表（核心表）
CREATE TABLE board_production_records (
    board_id VARCHAR(100) PRIMARY KEY, -- 每块主板唯一ID
    batch_id VARCHAR(50) NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    model_id VARCHAR(50) NOT NULL,
    serial_number VARCHAR(100) UNIQUE, -- 序列号
    pcb_id VARCHAR(100), -- PCB板ID
    production_date DATE NOT NULL,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    status VARCHAR(20) DEFAULT 'IN_PROGRESS', -- IN_PROGRESS, COMPLETED, DEFECTIVE, SCRAPPED
    quality_grade VARCHAR(10), -- A, B, C, REJECT
    defect_type VARCHAR(100), -- 缺陷类型
    defect_description TEXT,
    operator_id VARCHAR(50),
    line_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (batch_id) REFERENCES production_batches(batch_id),
    FOREIGN KEY (order_id) REFERENCES production_orders(order_id),
    FOREIGN KEY (model_id) REFERENCES product_models(model_id),
    FOREIGN KEY (line_id) REFERENCES production_lines(line_id)
);

-- 单板物料使用记录表
CREATE TABLE board_material_usage (
    usage_id SERIAL PRIMARY KEY,
    board_id VARCHAR(100) NOT NULL,
    material_id VARCHAR(50) NOT NULL,
    position_ref VARCHAR(100), -- 位置参考
    quantity_used DECIMAL(10,4) NOT NULL DEFAULT 1,
    unit VARCHAR(20) DEFAULT 'pcs',
    lot_number VARCHAR(100), -- 批次号
    supplier_batch VARCHAR(100), -- 供应商批次
    installation_time TIMESTAMP,
    operator_id VARCHAR(50),
    machine_id VARCHAR(50),
    status VARCHAR(20) DEFAULT 'INSTALLED', -- INSTALLED, MISSING, WRONG_POSITION
    notes TEXT,
    FOREIGN KEY (board_id) REFERENCES board_production_records(board_id),
    FOREIGN KEY (material_id) REFERENCES materials(material_id)
);

-- ========================================
-- 5. 质量检测相关表
-- ========================================

-- 检测项目表
CREATE TABLE inspection_items (
    item_id VARCHAR(50) PRIMARY KEY,
    item_name VARCHAR(100) NOT NULL,
    inspection_type VARCHAR(50), -- VISUAL, ELECTRICAL, FUNCTIONAL等
    standard_spec TEXT,
    tolerance VARCHAR(50),
    unit VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 单板检测记录表
CREATE TABLE board_inspection_records (
    inspection_id SERIAL PRIMARY KEY,
    board_id VARCHAR(100) NOT NULL,
    item_id VARCHAR(50) NOT NULL,
    inspection_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    inspector_id VARCHAR(50),
    result VARCHAR(20) NOT NULL, -- PASS, FAIL, CONDITIONAL
    measured_value DECIMAL(10,4),
    standard_value DECIMAL(10,4),
    deviation DECIMAL(10,4),
    notes TEXT,
    FOREIGN KEY (board_id) REFERENCES board_production_records(board_id),
    FOREIGN KEY (item_id) REFERENCES inspection_items(item_id)
);

-- ========================================
-- 6. 库存管理相关表
-- ========================================

-- 库存表
CREATE TABLE inventory (
    inventory_id SERIAL PRIMARY KEY,
    material_id VARCHAR(50) NOT NULL,
    warehouse_location VARCHAR(100),
    lot_number VARCHAR(100),
    quantity_on_hand DECIMAL(10,4) NOT NULL DEFAULT 0,
    quantity_reserved DECIMAL(10,4) DEFAULT 0,
    quantity_available DECIMAL(10,4) GENERATED ALWAYS AS (quantity_on_hand - quantity_reserved) STORED,
    unit VARCHAR(20) DEFAULT 'pcs',
    unit_cost DECIMAL(10,4),
    currency VARCHAR(3) DEFAULT 'CNY',
    expiry_date DATE,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (material_id) REFERENCES materials(material_id)
);

-- 库存事务表
CREATE TABLE inventory_transactions (
    transaction_id SERIAL PRIMARY KEY,
    material_id VARCHAR(50) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL, -- RECEIPT, ISSUE, ADJUSTMENT, TRANSFER
    quantity DECIMAL(10,4) NOT NULL,
    unit VARCHAR(20) DEFAULT 'pcs',
    reference_type VARCHAR(50), -- PURCHASE_ORDER, PRODUCTION_ORDER, ADJUSTMENT等
    reference_id VARCHAR(100),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    operator_id VARCHAR(50),
    notes TEXT,
    FOREIGN KEY (material_id) REFERENCES materials(material_id)
);

-- ========================================
-- 7. 设备管理相关表
-- ========================================

-- 设备表
CREATE TABLE machines (
    machine_id VARCHAR(50) PRIMARY KEY,
    machine_name VARCHAR(100) NOT NULL,
    machine_type VARCHAR(50), -- SMT_MACHINE, REFLOW_OVEN, AOI等
    model VARCHAR(100),
    manufacturer VARCHAR(100),
    serial_number VARCHAR(100),
    line_id VARCHAR(50),
    status VARCHAR(20) DEFAULT 'ACTIVE', -- ACTIVE, MAINTENANCE, INACTIVE
    installation_date DATE,
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (line_id) REFERENCES production_lines(line_id)
);

-- 设备维护记录表
CREATE TABLE machine_maintenance (
    maintenance_id SERIAL PRIMARY KEY,
    machine_id VARCHAR(50) NOT NULL,
    maintenance_type VARCHAR(50), -- PREVENTIVE, CORRECTIVE, EMERGENCY
    description TEXT,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    duration_hours DECIMAL(5,2),
    technician_id VARCHAR(50),
    parts_replaced TEXT,
    cost DECIMAL(10,2),
    notes TEXT,
    FOREIGN KEY (machine_id) REFERENCES machines(machine_id)
);

-- ========================================
-- 8. 人员管理相关表
-- ========================================

-- 员工表
CREATE TABLE employees (
    employee_id VARCHAR(50) PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    department VARCHAR(50),
    position VARCHAR(100),
    shift VARCHAR(20), -- DAY, NIGHT, ROTATING
    status VARCHAR(20) DEFAULT 'ACTIVE',
    hire_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================
-- 9. 索引优化
-- ========================================

-- 为常用查询字段创建索引
CREATE INDEX idx_board_production_records_batch_id ON board_production_records(batch_id);
CREATE INDEX idx_board_production_records_order_id ON board_production_records(order_id);
CREATE INDEX idx_board_production_records_model_id ON board_production_records(model_id);
CREATE INDEX idx_board_production_records_status ON board_production_records(status);
CREATE INDEX idx_board_production_records_production_date ON board_production_records(production_date);

CREATE INDEX idx_board_material_usage_board_id ON board_material_usage(board_id);
CREATE INDEX idx_board_material_usage_material_id ON board_material_usage(material_id);

CREATE INDEX idx_inventory_material_id ON inventory(material_id);
CREATE INDEX idx_inventory_lot_number ON inventory(lot_number);

CREATE INDEX idx_production_orders_status ON production_orders(status);
CREATE INDEX idx_production_orders_planned_start_date ON production_orders(planned_start_date);

-- ========================================
-- 10. 示例数据插入
-- ========================================

-- 插入示例产品型号
INSERT INTO product_models (model_id, model_name, product_type, description, revision) VALUES
('MB-001', 'iPhone 15 Pro主板', '手机主板', 'iPhone 15 Pro系列主板，支持A17 Pro芯片', 'V1.0'),
('MB-002', 'Samsung S24主板', '手机主板', 'Samsung Galaxy S24系列主板，支持骁龙8 Gen 3', 'V1.0');

-- 插入示例物料
INSERT INTO materials (material_id, material_name, part_number, manufacturer, category, sub_category, package_type, value_spec) VALUES
('R-001', '贴片电阻', '0805-10K', 'Yageo', 'RESISTOR', '0805', '0805', '10KΩ ±1%'),
('C-001', '贴片电容', '0603-100nF', 'Murata', 'CAPACITOR', '0603', '0603', '100nF ±10%'),
('IC-001', '电源管理IC', 'PMIC-001', 'TI', 'IC', 'POWER', 'QFN-32', '电源管理芯片'),
('CONN-001', 'USB-C连接器', 'USB-C-001', 'Molex', 'CONNECTOR', 'USB', 'SMT', 'USB-C 3.1');

-- 插入示例生产线
INSERT INTO production_lines (line_id, line_name, line_type, capacity_per_hour) VALUES
('LINE-001', 'SMT生产线1', 'SMT', 100),
('LINE-002', 'SMT生产线2', 'SMT', 120),
('LINE-003', '测试线1', 'TEST', 200);

-- 插入示例员工
INSERT INTO employees (employee_id, employee_name, department, position, shift) VALUES
('EMP-001', '张三', '生产部', 'SMT操作员', 'DAY'),
('EMP-002', '李四', '质量部', '质检员', 'DAY'),
('EMP-003', '王五', '工程部', '工艺工程师', 'DAY');

-- ========================================
-- 11. 视图创建
-- ========================================

-- 生产进度视图
CREATE VIEW production_progress AS
SELECT 
    po.order_id,
    po.model_id,
    pm.model_name,
    po.quantity_planned,
    po.quantity_completed,
    po.quantity_defective,
    ROUND((po.quantity_completed::DECIMAL / po.quantity_planned::DECIMAL) * 100, 2) as completion_rate,
    po.status,
    po.planned_start_date,
    po.planned_end_date
FROM production_orders po
JOIN product_models pm ON po.model_id = pm.model_id;

-- 物料库存状态视图
CREATE VIEW material_inventory_status AS
SELECT 
    m.material_id,
    m.material_name,
    m.category,
    m.sub_category,
    COALESCE(SUM(i.quantity_on_hand), 0) as total_stock,
    COALESCE(SUM(i.quantity_reserved), 0) as total_reserved,
    COALESCE(SUM(i.quantity_available), 0) as total_available,
    m.min_stock,
    m.max_stock,
    CASE 
        WHEN COALESCE(SUM(i.quantity_available), 0) <= m.min_stock THEN 'LOW_STOCK'
        WHEN COALESCE(SUM(i.quantity_available), 0) >= m.max_stock THEN 'OVERSTOCK'
        ELSE 'NORMAL'
    END as stock_status
FROM materials m
LEFT JOIN inventory i ON m.material_id = i.material_id
GROUP BY m.material_id, m.material_name, m.category, m.sub_category, m.min_stock, m.max_stock;

-- 单板生产统计视图
CREATE VIEW board_production_stats AS
SELECT 
    DATE(production_date) as production_date,
    model_id,
    COUNT(*) as total_boards,
    COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) as completed_boards,
    COUNT(CASE WHEN status = 'DEFECTIVE' THEN 1 END) as defective_boards,
    COUNT(CASE WHEN status = 'SCRAPPED' THEN 1 END) as scrapped_boards,
    ROUND(
        (COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END)::DECIMAL / COUNT(*)::DECIMAL) * 100, 2
    ) as yield_rate
FROM board_production_records
GROUP BY DATE(production_date), model_id
ORDER BY production_date DESC, model_id;

-- ========================================
-- 12. 存储过程示例
-- ========================================

-- 创建生产工单的存储过程
CREATE OR REPLACE FUNCTION create_production_order(
    p_order_id VARCHAR(50),
    p_model_id VARCHAR(50),
    p_bom_id VARCHAR(50),
    p_quantity INTEGER,
    p_planned_start_date DATE,
    p_line_id VARCHAR(50)
) RETURNS VOID AS $$
BEGIN
    -- 插入生产工单
    INSERT INTO production_orders (
        order_id, model_id, bom_id, quantity_planned, 
        planned_start_date, line_id, status
    ) VALUES (
        p_order_id, p_model_id, p_bom_id, p_quantity,
        p_planned_start_date, p_line_id, 'PLANNED'
    );
    
    -- 自动创建物料需求记录
    INSERT INTO order_material_requirements (
        order_id, material_id, required_quantity, unit
    )
    SELECT 
        p_order_id,
        bd.material_id,
        bd.quantity_per_unit * p_quantity,
        bd.unit
    FROM bom_details bd
    WHERE bd.bom_id = p_bom_id;
    
    RAISE NOTICE '生产工单 % 创建成功，数量: %', p_order_id, p_quantity;
END;
$$ LANGUAGE plpgsql;

-- 更新库存的存储过程
CREATE OR REPLACE FUNCTION update_inventory(
    p_material_id VARCHAR(50),
    p_quantity_change DECIMAL,
    p_transaction_type VARCHAR(20),
    p_reference_type VARCHAR(50),
    p_reference_id VARCHAR(100)
) RETURNS VOID AS $$
DECLARE
    v_current_stock DECIMAL;
BEGIN
    -- 获取当前库存
    SELECT COALESCE(SUM(quantity_on_hand), 0) INTO v_current_stock
    FROM inventory 
    WHERE material_id = p_material_id;
    
    -- 更新库存
    IF p_transaction_type = 'RECEIPT' THEN
        -- 入库
        INSERT INTO inventory (material_id, quantity_on_hand, unit)
        VALUES (p_material_id, p_quantity_change, 'pcs')
        ON CONFLICT (material_id) 
        DO UPDATE SET 
            quantity_on_hand = inventory.quantity_on_hand + p_quantity_change,
            last_updated = CURRENT_TIMESTAMP;
    ELSIF p_transaction_type = 'ISSUE' THEN
        -- 出库
        IF v_current_stock >= p_quantity_change THEN
            UPDATE inventory 
            SET 
                quantity_on_hand = quantity_on_hand - p_quantity_change,
                last_updated = CURRENT_TIMESTAMP
            WHERE material_id = p_material_id;
        ELSE
            RAISE EXCEPTION '库存不足，当前库存: %, 需要: %', v_current_stock, p_quantity_change;
        END IF;
    END IF;
    
    -- 记录库存事务
    INSERT INTO inventory_transactions (
        material_id, transaction_type, quantity, reference_type, reference_id
    ) VALUES (
        p_material_id, p_transaction_type, p_quantity_change, p_reference_type, p_reference_id
    );
    
    RAISE NOTICE '库存更新成功，物料: %, 变化: %, 类型: %', p_material_id, p_quantity_change, p_transaction_type;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 13. 触发器示例
-- ========================================

-- 自动更新库存可用数量的触发器
CREATE OR REPLACE FUNCTION update_available_quantity()
RETURNS TRIGGER AS $$
BEGIN
    -- 更新可用数量
    UPDATE inventory 
    SET quantity_available = quantity_on_hand - quantity_reserved
    WHERE material_id = NEW.material_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_available_quantity
    AFTER UPDATE OF quantity_on_hand, quantity_reserved ON inventory
    FOR EACH ROW
    EXECUTE FUNCTION update_available_quantity();

-- 自动更新工单完成数量的触发器
CREATE OR REPLACE FUNCTION update_order_completion()
RETURNS TRIGGER AS $$
BEGIN
    -- 更新工单完成数量
    UPDATE production_orders 
    SET 
        quantity_completed = (
            SELECT COUNT(*) 
            FROM board_production_records 
            WHERE order_id = NEW.order_id AND status = 'COMPLETED'
        ),
        updated_at = CURRENT_TIMESTAMP
    WHERE order_id = NEW.order_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_order_completion
    AFTER UPDATE OF status ON board_production_records
    FOR EACH ROW
    EXECUTE FUNCTION update_order_completion();

-- ========================================
-- 14. 权限管理
-- ========================================

-- 创建角色
CREATE ROLE production_operator;
CREATE ROLE quality_inspector;
CREATE ROLE production_manager;
CREATE ROLE system_admin;

-- 为角色分配权限
GRANT SELECT, INSERT, UPDATE ON board_production_records TO production_operator;
GRANT SELECT, INSERT, UPDATE ON board_material_usage TO production_operator;
GRANT SELECT ON materials TO production_operator;
GRANT SELECT ON product_models TO production_operator;

GRANT SELECT, INSERT, UPDATE ON board_inspection_records TO quality_inspector;
GRANT SELECT ON board_production_records TO quality_inspector;
GRANT SELECT ON inspection_items TO quality_inspector;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO production_manager;
GRANT INSERT, UPDATE ON production_orders TO production_manager;
GRANT INSERT, UPDATE ON production_batches TO production_manager;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO system_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO system_admin;

-- ========================================
-- 15. 数据备份和维护建议
-- ========================================

/*
数据库维护建议：

1. 定期备份：
   - 每日增量备份
   - 每周全量备份
   - 保留30天的备份历史

2. 性能优化：
   - 定期分析表统计信息
   - 监控慢查询
   - 根据业务增长调整索引

3. 数据清理：
   - 定期归档历史数据
   - 清理过期的临时数据
   - 维护合理的表分区

4. 监控指标：
   - 数据库连接数
   - 查询响应时间
   - 磁盘空间使用率
   - 锁等待情况

5. 安全措施：
   - 定期更新密码
   - 限制数据库访问IP
   - 启用审计日志
   - 数据加密存储
*/

COMMENT ON TABLE board_production_records IS '单板生产记录表 - 每块主板的生产过程记录';
COMMENT ON TABLE board_material_usage IS '单板物料使用记录表 - 记录每块主板上每个物料的使用情况';
COMMENT ON TABLE production_orders IS '生产工单表 - 管理生产任务和进度';
COMMENT ON TABLE materials IS '物料主数据表 - 存储所有物料的基本信息';
COMMENT ON TABLE product_boms IS '产品BOM表 - 定义产品的物料清单结构';
