resource "genesyscloud_integration_action" "action" {
    name           = var.action_name
    category       = var.action_category
    integration_id = var.integration_id
    secure         = var.secure_data_action
    
    contract_input  = jsonencode({
        "additionalProperties" = true,
        "properties" = {
            "phone" = {
                "type" = "string"
            }
        },
        "type" = "object"
    })
    contract_output = jsonencode({
        "additionalProperties" = true,
        "properties" = {
            "caseId" = {
                "type" = "string"
            },
            "caseNumber" = {
                "type" = "string"
            }
        },
        "type" = "object"
    })
    
    config_request {
        request_template     = "{\n    \"allOrNone\": true,\n    \"compositeRequest\": [{\n            \"method\": \"GET\",\n            \"referenceId\": \"Contact\",\n            \"url\": \"/services/data/v48.0/query/?q=SELECT Id FROM Contact WHERE Phone='$${input.phone}' LIMIT 1\"\n        }, {\n            \"method\": \"POST\",\n            \"referenceId\": \"NewCase1\",\n            \"url\": \"/services/data/v48.0/sobjects/Case\",\n            \"body\": {\n                \"ContactId\": \"@{Contact.records[0].Id}\",\n                \"Status\": \"New\",\n                \"Origin\": \"Phone\"\n            }\n        }, {\n            \"method\": \"GET\",\n            \"referenceId\": \"CaseInfo\",\n            \"url\": \"/services/data/v20.0/sobjects/Case/@{NewCase1.id}?fields=Id,CaseNumber\"\n        }\n    ]\n}"
        request_type         = "POST"
        request_url_template = "/services/data/v54.0/composite/"
    }

    config_response {
        success_template = "{ \"caseNumber\": $${successTemplateUtils.firstFromArray(\"$${caseNumArray}\", \"$esc.quote$esc.quote\")}, \"caseId\": $${successTemplateUtils.firstFromArray(\"$${caseIdArray}\", \"$esc.quote$esc.quote\")} }"
        translation_map = { 
			caseIdArray = "$.compositeResponse[?(@.body.attributes.type == 'Case')].body.Id"
			caseNumArray = "$.compositeResponse[?(@.body.attributes.type == 'Case')].body.CaseNumber"
		}
        translation_map_defaults = {       
			caseIdArray = "\"\""
			caseNumArray = "\"\""
		}
    }
}