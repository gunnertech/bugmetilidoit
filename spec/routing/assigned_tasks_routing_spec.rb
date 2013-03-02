require "spec_helper"

describe AssignedTasksController do
  describe "routing" do

    it "routes to #index" do
      get("/assigned_tasks").should route_to("assigned_tasks#index")
    end

    it "routes to #new" do
      get("/assigned_tasks/new").should route_to("assigned_tasks#new")
    end

    it "routes to #show" do
      get("/assigned_tasks/1").should route_to("assigned_tasks#show", :id => "1")
    end

    it "routes to #edit" do
      get("/assigned_tasks/1/edit").should route_to("assigned_tasks#edit", :id => "1")
    end

    it "routes to #create" do
      post("/assigned_tasks").should route_to("assigned_tasks#create")
    end

    it "routes to #update" do
      put("/assigned_tasks/1").should route_to("assigned_tasks#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/assigned_tasks/1").should route_to("assigned_tasks#destroy", :id => "1")
    end

  end
end
