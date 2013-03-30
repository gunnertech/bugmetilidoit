require "spec_helper"

describe AssignedNetworksController do
  describe "routing" do

    it "routes to #index" do
      get("/assigned_networks").should route_to("assigned_networks#index")
    end

    it "routes to #new" do
      get("/assigned_networks/new").should route_to("assigned_networks#new")
    end

    it "routes to #show" do
      get("/assigned_networks/1").should route_to("assigned_networks#show", :id => "1")
    end

    it "routes to #edit" do
      get("/assigned_networks/1/edit").should route_to("assigned_networks#edit", :id => "1")
    end

    it "routes to #create" do
      post("/assigned_networks").should route_to("assigned_networks#create")
    end

    it "routes to #update" do
      put("/assigned_networks/1").should route_to("assigned_networks#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/assigned_networks/1").should route_to("assigned_networks#destroy", :id => "1")
    end

  end
end
