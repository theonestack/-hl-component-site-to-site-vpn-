require 'yaml'

describe 'compiled component site-to-site-vpn' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/extended_tunnel_options.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/extended_tunnel_options/site-to-site-vpn.compiled.yaml") }
  
  context "Resource" do

    
    context "VPGW" do
      let(:resource) { template["Resources"]["VPGW"] }

      it "is of type AWS::EC2::VPNGateway" do
          expect(resource["Type"]).to eq("AWS::EC2::VPNGateway")
      end
      
      it "to have property Tags" do
          expect(resource["Properties"]["Tags"]).to eq([{"Key"=>"Name", "Value"=>{"Fn::Sub"=>"${EnvironmentName}-proxy-VPGW"}}])
      end
      
      it "to have property Type" do
          expect(resource["Properties"]["Type"]).to eq("ipsec.1")
      end
      
    end
    
    context "VPGWAttachment" do
      let(:resource) { template["Resources"]["VPGWAttachment"] }

      it "is of type AWS::EC2::VPCGatewayAttachment" do
          expect(resource["Type"]).to eq("AWS::EC2::VPCGatewayAttachment")
      end
      
      it "to have property VpcId" do
          expect(resource["Properties"]["VpcId"]).to eq({"Ref"=>"VPCId"})
      end
      
      it "to have property VpnGatewayId" do
          expect(resource["Properties"]["VpnGatewayId"]).to eq({"Ref"=>"VPGW"})
      end
      
    end
    
    context "CustomerGateway" do
      let(:resource) { template["Resources"]["CustomerGateway"] }

      it "is of type AWS::EC2::CustomerGateway" do
          expect(resource["Type"]).to eq("AWS::EC2::CustomerGateway")
      end
      
      it "to have property IpAddress" do
          expect(resource["Properties"]["IpAddress"]).to eq({"Ref"=>"CGWIpAddress"})
      end
      
      it "to have property Type" do
          expect(resource["Properties"]["Type"]).to eq("ipsec.1")
      end
      
      it "to have property BgpAsn" do
          expect(resource["Properties"]["BgpAsn"]).to eq(65000)
      end
      
      it "to have property Tags" do
          expect(resource["Properties"]["Tags"]).to eq([{"Key"=>"Name", "Value"=>{"Fn::Sub"=>"${EnvironmentName}-proxy-CGW"}}])
      end
      
    end
    
    context "VPNConnection" do
      let(:resource) { template["Resources"]["VPNConnection"] }

      it "is of type AWS::EC2::VPNConnection" do
          expect(resource["Type"]).to eq("AWS::EC2::VPNConnection")
      end
      
      it "to have property CustomerGatewayId" do
          expect(resource["Properties"]["CustomerGatewayId"]).to eq({"Ref"=>"CustomerGateway"})
      end
      
      it "to have property Type" do
          expect(resource["Properties"]["Type"]).to eq("ipsec.1")
      end
      
      it "to have property VpnGatewayId" do
          expect(resource["Properties"]["VpnGatewayId"]).to eq({"Ref"=>"VPGW"})
      end
      
      it "to have property Tags" do
          expect(resource["Properties"]["Tags"]).to eq([{"Key"=>"Name", "Value"=>{"Fn::Sub"=>"${EnvironmentName}-proxy-VPN"}}])
      end
      
    end
    
    context "VPNGatewayRoutePropagation" do
      let(:resource) { template["Resources"]["VPNGatewayRoutePropagation"] }

      it "is of type AWS::EC2::VPNGatewayRoutePropagation" do
          expect(resource["Type"]).to eq("AWS::EC2::VPNGatewayRoutePropagation")
      end
      
      it "to have property RouteTableIds" do
          expect(resource["Properties"]["RouteTableIds"]).to eq({"Ref"=>"RouteTableIds"})
      end
      
      it "to have property VpnGatewayId" do
          expect(resource["Properties"]["VpnGatewayId"]).to eq({"Ref"=>"VPGW"})
      end
      
    end
    
    context "ccrTunnelOptionsRole" do
      let(:resource) { template["Resources"]["ccrTunnelOptionsRole"] }

      it "is of type AWS::IAM::Role" do
          expect(resource["Type"]).to eq("AWS::IAM::Role")
      end
      
      it "to have property AssumeRolePolicyDocument" do
          expect(resource["Properties"]["AssumeRolePolicyDocument"]).to eq({"Version"=>"2012-10-17", "Statement"=>[{"Effect"=>"Allow", "Principal"=>{"Service"=>["lambda.amazonaws.com"]}, "Action"=>"sts:AssumeRole"}]})
      end
      
      it "to have property Path" do
          expect(resource["Properties"]["Path"]).to eq("/")
      end
      
      it "to have property Policies" do
          expect(resource["Properties"]["Policies"]).to eq([{"PolicyName"=>"vpcConnectionConfig", "PolicyDocument"=>{"Version"=>"2012-10-17", "Statement"=>[{"Effect"=>"Allow", "Action"=>["ec2:DescribeVpnConnections", "ec2:ModifyVpnTunnelOptions"], "Resource"=>"*"}, {"Effect"=>"Allow", "Action"=>["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource"=>"*"}]}}])
      end
      
    end
    
    context "ccrTunnelOptionsLogGroup" do
      let(:resource) { template["Resources"]["ccrTunnelOptionsLogGroup"] }

      it "is of type AWS::Logs::LogGroup" do
          expect(resource["Type"]).to eq("AWS::Logs::LogGroup")
      end
      
      it "to have property LogGroupName" do
          expect(resource["Properties"]["LogGroupName"]).to eq({"Fn::Sub"=>"/aws/lambda/${ccrTunnelOptionsFunction}"})
      end
      
      it "to have property RetentionInDays" do
          expect(resource["Properties"]["RetentionInDays"]).to eq(30)
      end
      
    end
    
    context "ccrTunnelOptionsFunction" do
      let(:resource) { template["Resources"]["ccrTunnelOptionsFunction"] }

      it "is of type AWS::Lambda::Function" do
          expect(resource["Type"]).to eq("AWS::Lambda::Function")
      end
      
      it "to have property Code" do
          expect(resource["Properties"]["Code"]).to eq({"ZipFile"=>"import cfnresponse\nimport boto3\nimport logging\nimport time\nimport json\nlogger = logging.getLogger(__name__)\nlogger.setLevel(logging.INFO)\ndef lambda_handler(event, context):\n    try:\n        logger.info(event)\n        responseData = {}\n        client = boto3.client('ec2')\n        if event['RequestType'] in ['Create', 'Update']:\n            logger.info(event['RequestType'])\n            vpnConnectionId = event['ResourceProperties']['VpnConnectionId']\n            response = client.describe_vpn_connections(VpnConnectionIds=[vpnConnectionId])\n            outsideIps = [x['OutsideIpAddress'] for x in response['VpnConnections'][0]['VgwTelemetry']]\n            tunnelOptions = json.loads(event['ResourceProperties']['TunnelOptions'])\n            for outsideIp in outsideIps:\n                waiter = client.get_waiter('vpn_connection_available')\n                waiter.wait(VpnConnectionIds=[vpnConnectionId])\n                response = client.modify_vpn_tunnel_options(VpnConnectionId=vpnConnectionId, VpnTunnelOutsideIpAddress=outsideIp, TunnelOptions=tunnelOptions)\n        elif event['RequestType'] == 'Delete':\n            logger.info(event['RequestType'])\n        cfnresponse.send(event, context, cfnresponse.SUCCESS, responseData)\n    except Exception as e:\n        logger.error('Failed to update vpn tunnel options', exc_info=True)\n        cfnresponse.send(event, context, cfnresponse.FAILED, {})\n"})
      end
      
      it "to have property Handler" do
          expect(resource["Properties"]["Handler"]).to eq("index.lambda_handler")
      end
      
      it "to have property Runtime" do
          expect(resource["Properties"]["Runtime"]).to eq("python3.11")
      end
      
      it "to have property Role" do
          expect(resource["Properties"]["Role"]).to eq({"Fn::GetAtt"=>["ccrTunnelOptionsRole", "Arn"]})
      end
      
      it "to have property Timeout" do
          expect(resource["Properties"]["Timeout"]).to eq(600)
      end
      
    end
    
    context "TunnelOptions" do
      let(:resource) { template["Resources"]["TunnelOptions"] }

      it "is of type Custom::TunnelOption" do
          expect(resource["Type"]).to eq("Custom::TunnelOption")
      end
      
      it "to have property ServiceToken" do
          expect(resource["Properties"]["ServiceToken"]).to eq({"Fn::GetAtt"=>["ccrTunnelOptionsFunction", "Arn"]})
      end
      
      it "to have property VpnConnectionId" do
          expect(resource["Properties"]["VpnConnectionId"]).to eq({"Ref"=>"VPNConnection"})
      end
      
      it "to have property TunnelOptions" do
          expect(resource["Properties"]["TunnelOptions"]).to eq('{"Phase1LifetimeSeconds":28800,"Phase2LifetimeSeconds":3600,"RekeyMarginTimeSeconds":540,"RekeyFuzzPercentage":100,"ReplayWindowSize":1024,"DPDTimeoutSeconds":30,"DPDTimeoutAction":"clear","StartupAction":"add","Phase1EncryptionAlgorithms":[{"Value":"AES128"},{"Value":"AES256"},{"Value":"AES128-GCM-16"},{"Value":"AES256-GCM-16"}],"Phase2EncryptionAlgorithms":[{"Value":"AES128"},{"Value":"AES256"},{"Value":"AES128-GCM-16"},{"Value":"AES256-GCM-16"}],"Phase1IntegrityAlgorithms":[{"Value":"SHA1"},{"Value":"SHA2-256"},{"Value":"SHA2-384"},{"Value":"SHA2-512"}],"Phase2IntegrityAlgorithms":[{"Value":"SHA1"},{"Value":"SHA2-256"},{"Value":"SHA2-384"},{"Value":"SHA2-512"}],"Phase1DHGroupNumbers":[{"Value":2},{"Value":14},{"Value":15},{"Value":16},{"Value":17},{"Value":18},{"Value":19},{"Value":20},{"Value":21},{"Value":22},{"Value":23},{"Value":24}],"Phase2DHGroupNumbers":[{"Value":2},{"Value":5},{"Value":14},{"Value":15},{"Value":16},{"Value":17},{"Value":18},{"Value":19},{"Value":20},{"Value":21},{"Value":22},{"Value":23},{"Value":24}],"IKEVersions":[{"Value":"ikev1"},{"Value":"ikev2"}]}')
      end
      
    end
    
  end

end