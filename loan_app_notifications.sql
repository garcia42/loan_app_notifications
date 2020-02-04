drop table if exists watchlist;
drop table if exists docs;
drop table if exists orders;
drop table if exists loan_apps;
drop table if exists notification_event;
drop table if exists users;
drop table if exists banks;
drop table if exists entities;

-- entity_type: 0 = users, 1 = banks
create table if not exists entities (
	id INT,
    entity_type TINYINT,
    PRIMARY key(id, entity_type)
);

create table if not exists banks (
	id INT,
    entity_type TINYINT,
    PRIMARY key(id,entity_type),
    bank_name varchar(255) NOT NULL,
    CONSTRAINT fk_banks_id
    FOREIGN KEY (id, entity_type)
		REFERENCES entities(id, entity_type)
);

create table if not exists users (
	id INT,
    entity_type TINYINT,
    PRIMARY key(id, entity_type),
    bank_id INT,
    user_name varchar(255) NOT NULL,
    CONSTRAINT fk_users_id
    FOREIGN KEY (id, entity_type)
		REFERENCES entities(id, entity_type),
	CONSTRAINT fk_bank_id
    FOREIGN KEY (bank_id)
		REFERENCES banks(id)
);

create table if not exists watchlist (
	id INT PRIMARY KEY,
    user_id INT,
    data_id INT,
    data_type TINYINT,
    CONSTRAINT fk_userid
    FOREIGN KEY (user_id)
		REFERENCES users(id)
);

-- data_types: loan_app = 0, order = 1, digi-doc = 2
create table if not exists notification_event (
    id INT AUTO_INCREMENT PRIMARY KEY,
    data_id INT,
    changedat DATETIME DEFAULT NULL,
    data_type TINYINT,
    is_read BOOLEAN,
    action VARCHAR(50) DEFAULT NULL,
    last_modified_id INT,
    CONSTRAINT fk_notification_lmID
    FOREIGN KEY (last_modified_id)
		REFERENCES entities(id)
);
CREATE INDEX sort_data_id ON notification_event(data_id);
CREATE INDEX sort_by_date ON notification_event (changedat);

create table if not exists loan_apps (
	id INT PRIMARY KEY,
    bank_id INT,
    user_id INT,
    loan_name varchar(255) NOT NULL,
    CONSTRAINT fk_loanapps_userid
    FOREIGN KEY (user_id)
		REFERENCES users(id),
	last_modified_id INT,
	CONSTRAINT fk_loans_lmID
    FOREIGN KEY (last_modified_id)
		REFERENCES entities(id)
);

create table if not exists orders (
	id INT PRIMARY KEY,
    bank_id INT,
    order_name varchar(255),
    loan_id INT,
    CONSTRAINT fk_loanid
    FOREIGN KEY (loan_id)
		REFERENCES loan_apps(id),
	last_modified_id INT,
	CONSTRAINT fk_orders_lmID
    FOREIGN KEY (last_modified_id)
		REFERENCES entities(id)
);

create table if not exists docs (
	id INT PRIMARY KEY,
    bank_id INT,
    doc_name varchar(255),
    order_id INT,
    CONSTRAINT fk_orderid
    FOREIGN KEY (order_id)
		REFERENCES orders(id),
	last_modified_id INT,
	CONSTRAINT fk_docs_lmID
    FOREIGN KEY (last_modified_id)
		REFERENCES entities(id)
);

DROP TRIGGER if exists loan_app_trigger_insert;
CREATE trigger loan_app_trigger_insert
	AFTER INSERT
    ON loan_apps FOR EACH ROW
    INSERT INTO notification_event
    SET action = "insert",
		data_id = NEW.id,
		data_type = 0,
        is_read = false,
		last_modified_id = NEW.last_modified_id,
		-- some unstructured metadata (as a json object)
		changedat = NOW();
    
DROP TRIGGER if exists loan_app_trigger_update;
CREATE trigger loan_app_trigger_update
	BEFORE UPDATE
    ON loan_apps FOR EACH ROW
    INSERT INTO notification_event
    SET action = "update",
    data_id = NEW.id,
    data_type = 0,
    is_read = false,
    last_modified_id = NEW.last_modified_id,
    -- some unstructured metadata (as a json object)
    changedat = NOW();

DROP TRIGGER if exists order_trigger_insert;
CREATE trigger order_trigger_insert
	BEFORE INSERT
    ON orders FOR EACH ROW
    INSERT INTO notification_event
    SET action = "insert",
    data_id = NEW.id,
    data_type = 1,
    is_read = false,
    last_modified_id = NEW.last_modified_id,
    -- some unstructured metadata (as a json object)
    changedat = NOW();

DROP TRIGGER if exists orders_trigger_update;
CREATE trigger orders_trigger_update
	BEFORE UPDATE
    ON orders FOR EACH ROW
    INSERT INTO notification_event
    SET action = "update",
    data_type = 1,
    data_id = NEW.id,
    is_read = false,
    last_modified_id = NEW.last_modified_id,
    -- some unstructured metadata (as a json object)
    changedat = NOW();
    
DROP TRIGGER if exists docs_trigger_insert;
CREATE trigger docs_trigger_insert
	BEFORE INSERT
    ON docs FOR EACH ROW
    INSERT INTO notification_event
    SET action = "insert",
    data_id = NEW.id,
    data_type = 2,
    is_read = false,
    last_modified_id = NEW.last_modified_id,
    -- some unstructured metadata (as a json object)
    changedat = NOW();

DROP TRIGGER if exists docs_trigger_update;
CREATE trigger docs_trigger_update
	BEFORE UPDATE
    ON docs FOR EACH ROW
    INSERT INTO notification_event
    SET action = "update",
    data_type = 2,
    is_read = false,
    data_id = NEW.id,
    last_modified_id = NEW.last_modified_id,
    -- some unstructured metadata (as a json object)
    changedat = NOW();

DROP TRIGGER if exists banks_trigger_insert;
CREATE trigger banks_trigger_insert
	BEFORE INSERT
    ON banks FOR EACH ROW
    INSERT INTO entities
    SET id = NEW.id,
		entity_type = 1;

DROP TRIGGER if exists banks_trigger_update;
CREATE trigger banks_trigger_update
	BEFORE UPDATE
    ON banks FOR EACH ROW
    INSERT INTO entities
    SET id = NEW.id,
		entity_type = 1;
        
DROP TRIGGER if exists users_trigger_insert;
CREATE 
    TRIGGER  users_trigger_insert
 BEFORE INSERT ON users FOR EACH ROW 
    INSERT INTO entities SET id = NEW.id , entity_type = 0;

DROP TRIGGER if exists users_trigger_update;
CREATE trigger users_trigger_update
	BEFORE UPDATE
    ON users FOR EACH ROW
    INSERT INTO entities
    SET id = NEW.id,
		entity_type = 0;

INSERT INTO banks(id, entity_type, bank_name)
VALUES (1, 1, "Chase");
INSERT INTO banks(id, entity_type, bank_name)
VALUES (2, 1, "BoA");
INSERT INTO banks(id, entity_type, bank_name)
VALUES (3, 1, "Wells Fargo");

INSERT INTO users(id, bank_id, user_name, entity_type)
VALUES (1, 1, "Jesus", 0);
INSERT INTO users(id, bank_id, user_name, entity_type)
VALUES (2, 1, "Henry", 0);
INSERT INTO users(id, bank_id, user_name, entity_type)
VALUES (3, 1, "Jordan", 0);

INSERT INTO loan_apps(id, bank_id, user_id, loan_name, last_modified_id)
VALUES (1, 1, 1, 'Jesus Loan', 1);
INSERT INTO loan_apps(id, bank_id, user_id, loan_name, last_modified_id)
VALUES (2, 1, 2, "Henry Loan", 1);
INSERT INTO loan_apps(id, bank_id, user_id, loan_name, last_modified_id)
VALUES (3, 1, 3, "Jordan Loan", 1);

INSERT INTO orders(id, bank_id, order_name, loan_id, last_modified_id)
VALUES (1, 1, "Jesus Order1", 1, 1);
INSERT INTO orders(id, bank_id, order_name, loan_id, last_modified_id)
VALUES (2, 1, "Jesus Order2", 1, 1);
INSERT INTO orders(id, bank_id, order_name, loan_id, last_modified_id)
VALUES (3, 1, "Jesus Order3", 1, 1);

INSERT INTO docs(id, bank_id, doc_name, order_id, last_modified_id)
VALUES (1, 1, "Jesus Doc1", 1, 1);
INSERT INTO docs(id, bank_id, doc_name, order_id, last_modified_id)
VALUES (2, 1, "Jesus Doc2", 1, 1);
INSERT INTO docs(id, bank_id, doc_name, order_id, last_modified_id)
VALUES (3, 1, "Jesus Doc3", 1, 1);

INSERT INTO watchlist(id, user_id, data_id, data_type)
VALUES (1, 1, 2, 2);

-- 2 Give me all the notifications for user id XXX, where XXX is the id, in the last 24 hours that are unread." We'd want this query to be efficient.
SELECT * FROM notification_event INNER JOIN watchlist ON notification_event.data_id = watchlist.data_id
	WHERE changedat >= now() - INTERVAL 1 DAY AND
    user_id = 1 AND
    notification_event.data_id = 2 AND
    is_read = FALSE;

-- 3 SQL statement using the schema that answers: "Give me all the notifications generated for order XXX". We'd want this query to be efficient.
-- SELECT * from notification_event WHERE data_type = 1 AND data_id = 5;