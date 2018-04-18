defmodule CodeFundWeb.CampaignControllerTest do
  use CodeFundWeb.ConnCase
  import SharedExample.ControllerTests
  import CodeFund.Factory

  setup do
    valid_params =
      string_params_with_assocs(:campaign)
      |> Map.merge(%{
        "bid_amount" => "2.0",
        "budget_daily_amount" => "25.0",
        "budget_monthly_amount" => "25.0",
        "budget_total_amount" => "25.0"
      })

    {:ok, %{valid_params: valid_params, users: stub_users()}}
  end

  describe "index" do
    fn conn, _context ->
      get(conn, campaign_path(conn, :index))
    end
    |> behaves_like([:authenticated, :sponsor], "GET /Campaigns")

    test "renders the index as a sponsor", %{conn: conn, users: users} do
      conn = assign(conn, :current_user, users.sponsor)
      campaign = insert(:campaign, user: users.sponsor)
      insert(:campaign)
      campaign = CodeFund.Campaigns.get_campaign!(campaign.id)
      conn = get(conn, campaign_path(conn, :index))

      assert conn.assigns.campaigns == [campaign]
      assert html_response(conn, 200) =~ "Campaigns"
    end

    test "renders the index as an admin", %{conn: conn, users: users} do
      conn = assign(conn, :current_user, users.admin)
      campaign = insert(:campaign)
      campaign = CodeFund.Campaigns.get_campaign!(campaign.id)
      conn = get(conn, campaign_path(conn, :index))

      assert conn.assigns.campaigns == [campaign]
      assert html_response(conn, 200) =~ "Campaigns"
    end
  end

  describe "new" do
    fn conn, _context ->
      get(conn, campaign_path(conn, :new))
    end
    |> behaves_like([:authenticated, :sponsor], "GET /campaigns/new")

    test "renders the new template", %{conn: conn} do
      conn = assign(conn, :current_user, insert(:user))
      conn = get(conn, campaign_path(conn, :new))

      assert html_response(conn, 200) =~ "Campaign"
    end
  end

  describe "create" do
    fn conn, context ->
      post(conn, campaign_path(conn, :create, %{"campaign" => context.valid_params}))
    end
    |> behaves_like([:authenticated, :sponsor], "POST /campaigns/create")

    test "creates a campaign", %{conn: conn, users: users, valid_params: valid_params} do
      conn = assign(conn, :current_user, users.sponsor)
      conn = post(conn, campaign_path(conn, :create, %{"campaign" => valid_params}))
      assert conn |> Phoenix.Controller.get_flash(:info) == "Campaign created successfully."

      assert redirected_to(conn, 302) ==
               campaign_path(conn, :show, CodeFund.Schema.Campaign |> CodeFund.Repo.one())
    end

    test "returns an error on invalid params for a campaign", %{
      conn: conn,
      users: users,
      valid_params: valid_params
    } do
      conn = assign(conn, :current_user, users.sponsor)

      conn =
        post(
          conn,
          campaign_path(conn, :create, %{"campaign" => valid_params |> Map.delete("name")})
        )

      assert html_response(conn, 422) =~
               "Oops, something went wrong! Please check the errors below."

      assert conn.assigns.form.errors == [name: ["can't be blank"]]
      assert conn.private.phoenix_template == "new.html"
    end
  end

  describe "show" do
    fn conn, _context ->
      get(conn, campaign_path(conn, :show, insert(:campaign)))
    end
    |> behaves_like([:authenticated, :sponsor], "GET /campaigns/:id")

    test "renders the show template", %{conn: conn} do
      conn = assign(conn, :current_user, insert(:user))
      campaign = insert(:campaign)
      conn = get(conn, campaign_path(conn, :show, campaign))

      assert html_response(conn, 200) =~ "Campaign"
      assert html_response(conn, 200) =~ campaign.name
    end
  end

  describe "edit" do
    fn conn, _context ->
      get(conn, campaign_path(conn, :edit, insert(:campaign)))
    end
    |> behaves_like([:authenticated, :sponsor], "GET /campaigns/edit")

    test "renders the edit template", %{conn: conn} do
      conn = assign(conn, :current_user, insert(:user))
      campaign = insert(:campaign)
      conn = get(conn, campaign_path(conn, :edit, campaign))

      assert html_response(conn, 200) =~ "Campaign"
      assert html_response(conn, 200) =~ campaign.name
    end
  end

  describe "update" do
    fn conn, _context ->
      patch(conn, campaign_path(conn, :update, insert(:campaign), %{"name" => "name"}))
    end
    |> behaves_like([:authenticated, :sponsor], "PATCH /campaigns/update")

    test "updates a campaign", %{conn: conn, users: users, valid_params: valid_params} do
      campaign = insert(:campaign)
      conn = assign(conn, :current_user, users.admin)

      conn =
        patch(
          conn,
          campaign_path(conn, :update, campaign, %{
            "campaign" => valid_params |> Map.put("name", "New Name")
          })
        )

      assert redirected_to(conn, 302) == campaign_path(conn, :show, campaign)
      assert CodeFund.Campaigns.get_campaign!(campaign.id).name == "New Name"
    end

    test "returns an error on invalid params for a campaign", %{
      conn: conn,
      users: users,
      valid_params: valid_params
    } do
      conn = assign(conn, :current_user, users.sponsor)

      conn =
        post(
          conn,
          campaign_path(conn, :create, %{"campaign" => valid_params |> Map.delete("name")})
        )

      assert html_response(conn, 422) =~
               "Oops, something went wrong! Please check the errors below."

      assert conn.assigns.form.errors == [name: ["can't be blank"]]
      assert conn.private.phoenix_template == "new.html"
    end
  end

  describe "delete" do
    fn conn, _context ->
      delete(conn, campaign_path(conn, :delete, insert(:campaign)))
    end
    |> behaves_like([:authenticated, :sponsor], "DELETE /campaigns/:id")

    test "deletes the campaign and redirects to index", %{conn: conn} do
      conn = assign(conn, :current_user, insert(:user))
      campaign = insert(:campaign)
      conn = delete(conn, campaign_path(conn, :delete, campaign))

      assert conn |> Phoenix.Controller.get_flash(:info) == "Campaign deleted successfully."
      assert redirected_to(conn, 302) == campaign_path(conn, :index)

      assert_raise Ecto.NoResultsError,
                   ~r/expected at least one result but got none in query/,
                   fn ->
                     CodeFund.Campaigns.get_campaign!(campaign.id).name == nil
                   end
    end
  end
end
