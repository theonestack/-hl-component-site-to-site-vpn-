CfhighlanderTemplate do
  Name 'site-to-site-vpn'
  
  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', allowedValues: ['development','production'], isGlobal: true
    ComponentParam 'VPCId', type: 'AWS::EC2::VPC::Id'
    ComponentParam 'CGWIpAddress', type: 'String'
    ComponentParam 'DestinationCidrBlock', '', type: 'String'
    ComponentParam 'RouteTableIds', '', type: 'CommaDelimitedList'
  end

end
