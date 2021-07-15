require 'yaml'

describe 'compiled component site-to-site-vpn' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/tunnel_options.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/tunnel_options/site-to-site-vpn.compiled.yaml") }
  
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
      
      it "to have property VpnTunnelOptionsSpecifications" do
          expect(resource["Properties"]["VpnTunnelOptionsSpecifications"]).to eq([{"PreSharedKey"=>"{{resolve:ssm:/environment/vpn/PreSharedKey:1}}"}, {"TunnelInsideCidr"=>"169.254.216.196/30"}])
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
    
  end

end