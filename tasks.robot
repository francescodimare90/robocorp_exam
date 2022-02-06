*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts

*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    credentials
    Open Available Browser    ${secret}[urlPage]

Get orders
    Add heading    Give me URL of csv orders file
    Add text input    url    label=URL
    ${urlCsv}=    Run dialog
    Download    url=${urlCsv.url}    overwrite=True
    ${table}=    Read table from CSV    orders.csv    header=True
    Log    Found columns: ${table.columns}
    [Return]    ${table}

Close the annoying modal
    Click Button    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Fill the form
    [Arguments]    ${row}
    Select From List By Value    //*[@id="head"]    ${row}[Head]
    Click Element    id-body-${row}[Body]
    Input Text    //html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    //*[@id="address"]    ${row}[Address]

Preview the robot
    Click Element    preview
    Screenshot    //*[@id="robot-preview-image"]    preview.png

Submit the order
    Wait Until Keyword Succeeds
    ...    5x
    ...    1s
    ...    Confirm order

Confirm order
    Click Button    order
    Wait Until Page Contains Element    //*[@id="receipt"]

Store the receipt as a PDF file
    [Arguments]    ${orderNumber}
    Wait Until Element Is Visible    //*[@id="receipt"]
    ${receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipts${/}${orderNumber}.pdf
    [Return]    ${OUTPUT_DIR}${/}receipts${/}${orderNumber}.pdf

Take a screenshot of the robot
    [Arguments]    ${orderNumber}
    Screenshot    filename=${OUTPUT_DIR}${/}screen${/}${orderNumber}.png
    [Return]    ${OUTPUT_DIR}${/}screen${/}${orderNumber}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${files}=    Create List    ${pdf}    ${screenshot}
    Add Files To Pdf    target_document=${pdf}    files=${files}

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/Receipts.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}receipts
    ...    ${zip_file_name}
