require 'json'
CloudFormation do

  EC2_VPNGateway(:VPGW) {
    Tags [{ Key: 'Name', Value: FnSub("${EnvironmentName}-proxy-VPGW")}]
    Type 'ipsec.1'
    if external_parameters[:vpn_gateway_ASN]
      AmazonSideAsn external_parameters[:vpn_gateway_ASN]
    end
  }

  EC2_VPCGatewayAttachment(:VPGWAttachment) {
    VpcId Ref('VPCId')
    VpnGatewayId Ref(:VPGW)
  }

  EC2_CustomerGateway(:CustomerGateway) {
    IpAddress Ref('CGWIpAddress')
    Type 'ipsec.1'
    BgpAsn external_parameters[:customer_gateway_bgpasn]
    Tags [{ Key: 'Name', Value: FnSub("${EnvironmentName}-proxy-CGW")}]
  }

  EC2_VPNConnection(:VPNConnection) {
    CustomerGatewayId Ref(:CustomerGateway)
    Type 'ipsec.1'
    VpnGatewayId Ref(:VPGW)
    Tags [{ Key: 'Name', Value: FnSub("${EnvironmentName}-proxy-VPN")}]
    if external_parameters[:static_routes_only]
      StaticRoutesOnly external_parameters[:static_routes_only]
    end

    if external_parameters[:tunnel_options]
      VpnTunnelOptionsSpecifications external_parameters[:tunnel_options]
    end 
  }

  EC2_VPNGatewayRoutePropagation(:VPNGatewayRoutePropagation) {
    DependsOn :VPGWAttachment
    RouteTableIds Ref('RouteTableIds')
    VpnGatewayId Ref(:VPGW)
  }


  if external_parameters[:static_routes_only]
    EC2_VPNConnectionRoute(:VPNConnectionRoute) {
      DestinationCidrBlock Ref('DestinationCidrBlock')
      VpnConnectionId Ref(:VPNConnection)
    }
  end

  if external_parameters[:tunnel_options_extended]
    IAM_Role(:ccrTunnelOptionsRole) {
      AssumeRolePolicyDocument({
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Principal: {
              Service: [
                'lambda.amazonaws.com'
              ]
            },
            Action: 'sts:AssumeRole'
          }
        ]
      })
      Path '/'
      Policies([
        {
          PolicyName: 'vpcConnectionConfig',
          PolicyDocument: {
            Version: '2012-10-17',
            Statement: [
              {
                Effect: 'Allow',
                Action: [
                  'ec2:DescribeVpnConnections',
                  'ec2:ModifyVpnTunnelOptions'
                ],
                Resource: '*'
              },
              {
                Effect: 'Allow',
                Action: [
                  'logs:CreateLogGroup',
                  'logs:CreateLogStream',
                  'logs:PutLogEvents'
                ],
                Resource: '*'
              }
            ]
          }
        }
      ])
    }

    Logs_LogGroup(:ccrTunnelOptionsLogGroup) {
      LogGroupName FnSub("/aws/lambda/${ccrTunnelOptionsFunction}")
      RetentionInDays 30
    }

    Lambda_Function(:ccrTunnelOptionsFunction) {
      Code({
        ZipFile: <<~CODE
        import cfnresponse
        import boto3
        import logging
        import time
        import json
        logger = logging.getLogger(__name__)
        logger.setLevel(logging.INFO)
        def lambda_handler(event, context):
            try:
                logger.info(event)
                responseData = {}
                client = boto3.client('ec2')
                if event['RequestType'] in ['Create', 'Update']:
                    logger.info(event['RequestType'])
                    vpnConnectionId = event['ResourceProperties']['VpnConnectionId']
                    response = client.describe_vpn_connections(VpnConnectionIds=[vpnConnectionId])
                    outsideIps = [x['OutsideIpAddress'] for x in response['VpnConnections'][0]['VgwTelemetry']]
                    tunnelOptions = json.loads(event['ResourceProperties']['TunnelOptions'])
                    for outsideIp in outsideIps:
                        waiter = client.get_waiter('vpn_connection_available')
                        waiter.wait(VpnConnectionIds=[vpnConnectionId])
                        response = client.modify_vpn_tunnel_options(VpnConnectionId=vpnConnectionId, VpnTunnelOutsideIpAddress=outsideIp, TunnelOptions=tunnelOptions)
                elif event['RequestType'] == 'Delete':
                    logger.info(event['RequestType'])
                cfnresponse.send(event, context, cfnresponse.SUCCESS, responseData)
            except Exception as e:
                logger.error('Failed to update vpn tunnel options', exc_info=True)
                cfnresponse.send(event, context, cfnresponse.FAILED, {})
        CODE
      })
      Handler "index.lambda_handler"
      Runtime "python3.11"
      Role FnGetAtt(:ccrTunnelOptionsRole, :Arn)
      Timeout 600
    }

    Resource("TunnelOptions") {
      Type "Custom::TunnelOption"
      Property 'ServiceToken', FnGetAtt('ccrTunnelOptionsFunction', 'Arn')
      Property 'VpnConnectionId', Ref(:VPNConnection)
      Property 'TunnelOptions', external_parameters[:tunnel_options_extended].to_json
    }


  end

end