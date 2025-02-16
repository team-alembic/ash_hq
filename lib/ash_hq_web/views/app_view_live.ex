defmodule AshHqWeb.AppViewLive do
  # credo:disable-for-this-file Credo.Check.Readability.MaxLineLength
  use Surface.LiveView,
    container: {:div, class: "h-full"}

  alias AshHqWeb.Components.{CatalogueModal, Search}
  alias AshHqWeb.Components.AppView.TopBar
  alias AshHqWeb.Pages.{Docs, Home, LogIn, Register, ResetPassword, UserSettings}
  alias Phoenix.LiveView.JS
  alias Surface.Components.Context
  require Ash.Query

  data configured_theme, :string, default: :system
  data searching, :boolean, default: false
  data selected_versions, :map, default: %{}
  data libraries, :list, default: []
  data selected_types, :map, default: %{}
  data current_user, :map

  data library, :any, default: nil
  data extension, :any, default: nil
  data docs, :any, default: nil
  data library_version, :any, default: nil
  data guide, :any, default: nil
  data doc_path, :list, default: []
  data dsls, :list, default: []
  data dsl, :any, default: nil
  data options, :list, default: []
  data module, :any, default: nil

  def render(%{platform: :ios} = assigns) do
    ~F"""
    {#case @live_action}
      {#match :home}
        <Home id="home" />
    {/case}
    """
  end

  def render(assigns) do
    ~F"""
    <div
      id="app"
      class={"h-full font-sans": true, "#{@configured_theme}": true}
      phx-hook="ColorTheme"
    >
      <Search
        id="search-box"
        close={close_search()}
        libraries={@libraries}
        selected_types={@selected_types}
        change_types="change-types"
        selected_versions={@selected_versions}
        change_versions="change-versions"
        remove_version="remove_version"
      />
      <CatalogueModal
        id="catalogue-box"
        libraries={@libraries}
        selected_versions={@selected_versions}
        change_versions="change-versions"
      />
      <button id="search-button" class="hidden" phx-click={AshHqWeb.AppViewLive.toggle_search()} />
      <div
        id="main-container"
        class={
          "h-screen w-screen bg-white dark:bg-base-dark-900 dark:text-white flex flex-col items-stretch",
          "overflow-y-auto overflow-x-hidden": @live_action == :home,
          "overflow-hidden": @live_action == :docs_dsl
        }
      >
        <TopBar
          live_action={@live_action}
          toggle_theme="toggle_theme"
          configured_theme={@configured_theme}
          current_user={@current_user}
        />
        {#for flash <- List.wrap(live_flash(@flash, :error))}
          <p class="alert alert-warning" role="alert">{flash}</p>
        {/for}
        {#for flash <- List.wrap(live_flash(@flash, :info))}
          <p class="alert alert-info max-h-min" role="alert">{flash}</p>
        {/for}
        {#case @live_action}
          {#match :home}
            <Home id="home" device_brand={@device_brand} />
          {#match :docs_dsl}
            <Docs
              id="docs"
              uri={@uri}
              params={@params}
              remove_version="remove_version"
              change_versions="change-versions"
              selected_versions={@selected_versions}
              libraries={@libraries}
            />
          {#match :user_settings}
            <UserSettings id="user_settings" current_user={@current_user} />
          {#match :log_in}
            <LogIn id="log_in" />
          {#match :register}
            <Register id="register" />
          {#match :reset_password}
            <ResetPassword id="reset_password" params={@params} />
        {/case}
        {#if @live_action != :docs_dsl}
          <footer class="relative p-8 sm:p-6 bg-base-light-200 dark:bg-base-dark-800 sm:justify-center">
            <div class="md:flex md:justify-around">
              <div class="flex justify-center mb-6 md:mb-0">
                <a href="/" class="flex items-center">
                  <img src="/images/ash-logo-side.svg" class="mr-3 h-32" alt="Ash Framework Logo">
                </a>
              </div>
              <div class="grid grid-cols-3 gap-8 sm:gap-6">
                <div>
                  <h2 class="mb-6 text-sm font-semibold text-gray-900 uppercase dark:text-white">Resources</h2>
                  <ul class="text-gray-600 dark:text-gray-400">
                    <li class="mb-4">
                      <a href="https://github.com/ash-project" class="hover:underline">Source</a>
                    </li>
                    <li>
                      <a href="/docs/guides/ash/latest/tutorials/get-started.md" class="hover:underline">Get Started</a>
                    </li>
                  </ul>
                </div>
                <div>
                  <h2 class="mb-6 text-sm font-semibold text-gray-900 uppercase dark:text-white">Community</h2>
                  <ul class="text-gray-600 dark:text-gray-400">
                    <li class="mb-4">
                      <a href="https://twitter.com/AshFramework" class="hover:underline">Twitter</a>
                    </li>
                    <li>
                      <a href="https://discord.gg/D7FNG2q" class="hover:underline">Discord</a>
                    </li>
                  </ul>
                </div>
                <div>
                  <h2 class="mb-6 text-sm font-semibold text-gray-900 uppercase dark:text-white">Help Us</h2>
                  <ul class="text-gray-600 dark:text-gray-400">
                    <li class="mb-4">
                      <a href="https://github.com/ash-project/ash_hq/issues/new/choose" class="hover:underline">Report an issue</a>
                    </li>
                    <li>
                      <a href="/docs/guides/ash/latest/how_to/contribute.md" class="hover:underline">Contribute</a>
                    </li>
                  </ul>
                </div>
              </div>
            </div>
          </footer>
        {/if}
      </div>
    </div>
    """
  end

  def handle_params(params, uri, socket) do
    {:noreply,
     socket
     |> assign(params: params, uri: uri)}
  end

  def handle_event("remove_version", %{"library" => library}, socket) do
    new_selected_versions = Map.put(socket.assigns.selected_versions, library, "")

    {:noreply,
     socket
     |> assign(:selected_versions, new_selected_versions)
     |> push_event("selected-versions", new_selected_versions)}
  end

  def handle_event("add_version", %{"library" => library}, socket) do
    new_selected_versions = Map.put(socket.assigns.selected_versions, library, "latest")

    {:noreply,
     socket
     |> assign(:selected_versions, new_selected_versions)
     |> push_event("selected-versions", new_selected_versions)}
  end

  def handle_event("change-versions", %{"versions" => versions}, socket) do
    {:noreply,
     socket
     |> assign(:selected_versions, versions)
     |> push_event("selected-versions", versions)}
  end

  def handle_event("change-types", %{"types" => types}, socket) do
    types =
      types
      |> Enum.filter(fn {_, value} ->
        value == "true"
      end)
      |> Enum.map(&elem(&1, 0))

    {:noreply,
     socket
     |> assign(
       :selected_types,
       types
     )
     |> push_event("selected-types", %{types: types})}
  end

  def handle_event("toggle_theme", _, socket) do
    theme =
      case socket.assigns.configured_theme do
        "light" ->
          "dark"

        "dark" ->
          "system"

        "system" ->
          "light"
      end

    {:noreply,
     socket
     |> assign(:configured_theme, theme)
     |> push_event("set_theme", %{theme: theme})}
  end

  def mount(params, session, socket) do
    socket =
      assign_new(socket, :user_agent, fn _assigns ->
        get_connect_params(socket)["user_agent"]
      end)

    socket =
      case socket.assigns[:user_agent] do
        empty when empty in [nil, ""] ->
          assign(socket, :device_brand, :unknown)

        ua ->
          assign(socket, :device_brand, UAInspector.parse(ua).device.brand)
      end

    socket = Context.put(socket, platform: socket.assigns.platform)
    configured_theme = session["theme"] || "system"

    configured_library_versions =
      case session["selected_versions"] do
        nil ->
          %{}

        "" ->
          %{}

        value ->
          value
          |> String.split(",")
          |> Map.new(fn str ->
            str
            |> String.split(":")
            |> List.to_tuple()
          end)
      end

    all_types = AshHq.Docs.Extensions.Search.Types.types()

    selected_types =
      case session["selected_types"] do
        nil ->
          AshHq.Docs.Extensions.Search.Types.types()

        types ->
          types
          |> String.split(",")
          |> Enum.filter(&(&1 in all_types))
      end

    versions_query =
      AshHq.Docs.LibraryVersion
      |> Ash.Query.sort(version: :desc)

    libraries = AshHq.Docs.Library.read!(load: [versions: versions_query])

    selected_versions =
      Enum.reduce(libraries, configured_library_versions, fn library, acc ->
        if library.name == "ash" do
          Map.put_new(acc, library.id, "latest")
        else
          Map.put_new(acc, library.id, "")
        end
      end)

    {:ok,
     socket
     |> assign(:libraries, libraries)
     |> assign(
       :selected_versions,
       selected_versions
     )
     |> assign(
       :selected_types,
       selected_types
     )
     |> assign(:selected_versions, selected_versions)
     |> assign(configured_theme: configured_theme)
     |> push_event("selected-versions", selected_versions)
     |> push_event("selected_types", %{types: selected_types})}
  end

  def toggle_search(js \\ %JS{}) do
    js
    |> JS.toggle(
      to: "#search-box",
      in: {
        "transition ease-in duration-100",
        "opacity-0",
        "opacity-100"
      },
      out: {
        "transition ease-out duration-75",
        "opacity-100",
        "opacity-0"
      }
    )
    |> JS.dispatch("js:focus", to: "#search-input")
  end

  def toggle_catalogue(js \\ %JS{}) do
    js
    |> JS.toggle(
      to: "#catalogue-box",
      in: {
        "transition ease-in duration-100",
        "opacity-0",
        "opacity-100"
      },
      out: {
        "transition ease-out duration-75",
        "opacity-100",
        "opacity-0"
      }
    )
  end

  def close_search(js \\ %JS{}) do
    js
    |> JS.hide(
      transition: "fade-out",
      to: "#search-box"
    )
    |> JS.hide(transition: "fade-out", to: "#search-versions")
    |> JS.show(transition: "fade-in", to: "#search-body")
  end

  def close_catalogue(js \\ %JS{}) do
    js
    |> JS.hide(
      transition: "fade-out",
      to: "#catalogue-box"
    )
  end
end
