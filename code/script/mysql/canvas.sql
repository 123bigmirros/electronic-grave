CREATE TABLE ImageBox (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    pid BIGINT,               -- Parent ID for the ImageBox
    imageUrl VARCHAR(255),    -- URL of the image in the box
    left_location INT,                 -- Left position of the text box
    top_location INT,                  -- Top position of the text box
    width_location INT,                -- Width of the text box
    height_location INT               -- Height of the text box
);
CREATE TABLE TextBox (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    pid BIGINT,               -- Parent ID for the TestBox
    content TEXT,     -- Content of the text box
    left_location INT,                 -- Left position of the text box
    top_location INT,                  -- Top position of the text box
    width_location INT,                -- Width of the text box
    height_location INT               -- Height of the text box
);

-- Creating CanvasDTO table
CREATE TABLE CanvasDTO (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    uId BIGINT
)
