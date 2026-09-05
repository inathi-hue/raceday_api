
    CREATE DATABASE RaceDayDB;

    use RaceDayDB;



-- Drop tables if re-running this script, children before parents
IF OBJECT_ID('dbo.Results', 'U')     IS NOT NULL DROP TABLE dbo.Results;
IF OBJECT_ID('dbo.Enrolments', 'U')  IS NOT NULL DROP TABLE dbo.Enrolments;
IF OBJECT_ID('dbo.Categories', 'U')  IS NOT NULL DROP TABLE dbo.Categories;
IF OBJECT_ID('dbo.Events', 'U')      IS NOT NULL DROP TABLE dbo.Events;
IF OBJECT_ID('dbo.Organiser', 'U')   IS NOT NULL DROP TABLE dbo.Organiser;
IF OBJECT_ID('dbo.Users', 'U')       IS NOT NULL DROP TABLE dbo.Users;
GO

/* =========================== 1. USERS =================================== */
CREATE TABLE dbo.Users (
    user_id     INT IDENTITY(1,1) NOT NULL,
    username    VARCHAR(50)  NOT NULL,
    user_role   VARCHAR(20)  NOT NULL DEFAULT 'Participant',
    created_at  DATETIME2    NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Users PRIMARY KEY (user_id),
    CONSTRAINT UQ_Users_Username UNIQUE (username),
    CONSTRAINT CK_Users_Role CHECK (user_role IN ('Organiser','Participant'))
);
GO

/* ==================== 2. ORGANISER (extends Users) ======================= */
-- Organiser_id shares the same value as the Users.user_id of an organiser
-- account (a 1-to-1 "profile extension" table).
CREATE TABLE dbo.Organiser (
    Organiser_id    INT          NOT NULL,
    organiser_name  VARCHAR(100) NOT NULL,
    created_at      DATETIME2    NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Organiser PRIMARY KEY (Organiser_id),
    CONSTRAINT FK_Organiser_Users FOREIGN KEY (Organiser_id)
        REFERENCES dbo.Users(user_id)
);
GO

/* =========================== 3. EVENTS =================================== */
CREATE TABLE dbo.Events (
    Event_id           INT IDENTITY(1,1) NOT NULL,
    Event_name         VARCHAR(100) NOT NULL,
    Location           VARCHAR(150) NOT NULL,
    Event_Description  VARCHAR(500) NULL,
    Event_date         DATE         NOT NULL,
    Event_type         VARCHAR(50)  NOT NULL,
    user_id            INT          NOT NULL, -- Organiser who created the event
    created_at         DATETIME2    NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Events PRIMARY KEY (Event_id),
    CONSTRAINT FK_Events_Organiser FOREIGN KEY (user_id)
        REFERENCES dbo.Organiser(Organiser_id)
);
GO

/* ========================= 4. CATEGORIES ================================= */
CREATE TABLE dbo.Categories (
    Category_id     INT IDENTITY(1,1) NOT NULL,
    Category_title  VARCHAR(100) NOT NULL,
    user_id         INT          NOT NULL, -- Organiser who manages the category
    Event_id        INT          NOT NULL, -- ** added: see note at top of file **
    created_at      DATETIME2    NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Categories PRIMARY KEY (Category_id),
    CONSTRAINT FK_Categories_Organiser FOREIGN KEY (user_id)
        REFERENCES dbo.Organiser(Organiser_id),
    CONSTRAINT FK_Categories_Events FOREIGN KEY (Event_id)
        REFERENCES dbo.Events(Event_id)
);
GO

/* ========================= 5. ENROLMENTS ================================= */
CREATE TABLE dbo.Enrolments (
    Enrolment_id  INT IDENTITY(1,1) NOT NULL,
    user_id       INT          NOT NULL, -- Participant enrolling
    username      VARCHAR(50)  NOT NULL, -- denormalised copy for quick lookup
    Category_id   INT          NOT NULL, -- ** added: see note at top of file **
    created_at    DATETIME2    NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Enrolments PRIMARY KEY (Enrolment_id),
    CONSTRAINT FK_Enrolments_Users FOREIGN KEY (user_id)
        REFERENCES dbo.Users(user_id),
    CONSTRAINT FK_Enrolments_Categories FOREIGN KEY (Category_id)
        REFERENCES dbo.Categories(Category_id)
);
GO

/* =========================== 6. RESULTS =================================== */
-- One result row per participant, matching the ERD's user_id-as-PK design.
CREATE TABLE dbo.Results (
    user_id         INT          NOT NULL, -- Participant the result belongs to
    username        VARCHAR(50)  NOT NULL,
    Category_title  VARCHAR(100) NOT NULL,
    Event_type      VARCHAR(50)  NOT NULL,
    created_at      DATETIME2    NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Results PRIMARY KEY (user_id),
    CONSTRAINT FK_Results_Users FOREIGN KEY (user_id)
        REFERENCES dbo.Users(user_id)
);
GO

/* ============================================================================
   SEED DATA - 2 Organisers, 2 Participants, 3 Events, categories for each
   event, and sample enrolments.
   ============================================================================ */

-- Users: 2 organisers (user_id 1,2) + 2 participants (user_id 3,4)
INSERT INTO dbo.Users (username, user_role) VALUES
('sarah.organiser', 'Organiser'),
('mike.organiser',  'Organiser'),
('thabo.runner',    'Participant'),
('lindiwe.cyclist', 'Participant');
GO

-- Organiser profile rows (Organiser_id = matching Users.user_id)
INSERT INTO dbo.Organiser (Organiser_id, organiser_name) VALUES
(1, 'Sarah Naidoo - Comrades Marathon Association'),
(2, 'Mike van der Merwe - Cape Town Cycle Tour');
GO

-- Events (3 events)
INSERT INTO dbo.Events (Event_name, Location, Event_Description, Event_date, Event_type, user_id) VALUES
('Comrades Marathon 2027',     'Pietermaritzburg to Durban', 'Iconic ultramarathon between PMB and Durban.',    '2027-06-13', 'Running', 1),
('Cape Town Cycle Tour 2027',  'Cape Town',                  'Scenic cycling tour around the Cape Peninsula.',   '2027-03-08', 'Cycling', 2),
('Soweto Marathon 2027',       'Soweto, Johannesburg',       'Community road running event through Soweto.',    '2027-11-07', 'Running', 1);
GO

-- Categories (linked to their event; Event_id 1 = Comrades, 2 = Cycle Tour, 3 = Soweto)
INSERT INTO dbo.Categories (Category_title, user_id, Event_id) VALUES
('Comrades - Up Run 90km',   1, 1),
('Comrades - Novice 56km',   1, 1),
('Cycle Tour - 109km Full',  2, 2),
('Cycle Tour - 42km Mini',   2, 2),
('Soweto - 10km Fun Run',    1, 3);
GO

-- Enrolments (Category_id 2 = Comrades Novice, 3 = Cycle Tour Full, 5 = Soweto 10km)
INSERT INTO dbo.Enrolments (user_id, username, Category_id) VALUES
(3, 'thabo.runner',    2),
(4, 'lindiwe.cyclist', 3),
(3, 'thabo.runner',    5);
GO

-- Results (one summary row per participant)
INSERT INTO dbo.Results (user_id, username, Category_title, Event_type) VALUES
(3, 'thabo.runner',    'Comrades - Novice 56km',  'Running'),
(4, 'lindiwe.cyclist', 'Cycle Tour - 109km Full', 'Cycling');
GO

-- Quick sanity check - run these after the script to confirm it worked
-- SELECT * FROM dbo.Users;
-- SELECT * FROM dbo.Organiser;
-- SELECT * FROM dbo.Events;
-- SELECT * FROM dbo.Categories;
-- SELECT * FROM dbo.Enrolments;
-- SELECT * FROM dbo.Results;