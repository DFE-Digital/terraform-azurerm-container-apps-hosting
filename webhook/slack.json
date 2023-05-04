{
  "channel": "${channel}",
  "text": "@{triggerBody()?['data']?['essentials']?['alertRule']}: @{triggerBody()?['data']?['essentials']?['monitorCondition']}",
  "blocks": [],
  "attachments": [
    {
      "blocks": [
        {
          "text": {
            "text": "<!here>",
            "type": "mrkdwn"
          },
          "type": "section"
        },
        {
          "text": {
            "text": "@{triggerBody()?['data']?['essentials']?['alertRule']}",
            "type": "plain_text"
          },
          "type": "header"
        },
        {
          "text": {
            "text": "_@{triggerBody()?['data']?['essentials']?['description']}_",
            "type": "mrkdwn"
          },
          "type": "section"
        },
        {
          "text": {
            "text": "*Alarm status:* @{triggerBody()?['data']?['essentials']?['monitorCondition']}",
            "type": "mrkdwn"
          },
          "type": "section"
        },
        {
          "fields": [
            {
              "text": "*Resource Group*",
              "type": "mrkdwn"
            },
            {
              "text": "@{variables('affectedResource')[4]} ",
              "type": "plain_text"
            },
            {
              "text": "*Provider*",
              "type": "mrkdwn"
            },
            {
              "text": "@{variables('AffectedResource')[6]} ",
              "type": "plain_text"
            },
            {
              "text": "*Severity*",
              "type": "mrkdwn"
            },
            {
              "text": "@{triggerBody()?['data']?['essentials']?['severity']} ",
              "type": "plain_text"
            },
            {
              "text": "*Metric definition*",
              "type": "mrkdwn"
            },
            {
              "text": "@{variables('alarmContext')['metricName']} @{variables('alarmContext')['timeAggregation']} @{variables('alarmContext')['operator']} @{variables('alarmContext')['threshold']}",
              "type": "plain_text"
            },
            {
              "text": "*Recorded value*",
              "type": "mrkdwn"
            },
            {
              "text": "@{variables('alarmContext')['metricValue']} ",
              "type": "plain_text"
            }
          ],
          "type": "section"
        }
      ],
      "color": "@{if(equals(triggerBody()?['data']?['essentials']?['monitorCondition'], 'Resolved'), '#50C878', '#D22B2B')}"
    }
  ]
}
