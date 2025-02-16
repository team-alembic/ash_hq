defmodule AshHqWeb.Components.Search do
  @moduledoc "The search overlay modal"
  use Surface.LiveComponent

  require Ash.Query

  alias AshHqWeb.Components.{CalloutText, Catalogue}
  alias AshHqWeb.DocRoutes
  alias Phoenix.LiveView.JS
  alias Surface.Components.Form
  alias Surface.Components.Form.{Checkbox, Label}

  prop close, :event, required: true
  prop libraries, :list, required: true
  prop selected_versions, :map, required: true
  prop selected_types, :list, required: true
  prop change_types, :event, required: true
  prop change_versions, :event, required: true
  prop remove_version, :event, required: true

  data search, :string, default: ""
  data item_list, :list, default: []
  data selected_item, :string
  data selecting_packages, :boolean, default: false

  def render(assigns) do
    ~F"""
    <div
      id={@id}
      style="display: none;"
      class="absolute flex justify-center align-middle w-screen h-full backdrop-blur-sm bg-white bg-opacity-10 z-50"
    >
      <div
        :on-click-away={AshHqWeb.AppViewLive.toggle_search()}
        class="dark:text-white absolute rounded-xl left-1/2 top-1/2 transform -translate-x-1/2 -translate-y-1/2 w-3/4 h-3/4 bg-white dark:bg-base-dark-900 border-2 dark:border-base-dark-900"
        :on-window-keydown="select-previous"
        phx-key="ArrowUp"
      >
        <div class="h-full w-full" id="search-versions" style="display: none;">
          <Catalogue
            id="search-versions-contents"
            toggle={toggle_libraries()}
            libraries={@libraries}
            selected_versions={@selected_versions}
            change_versions={@change_versions}
          />
        </div>
        <div
          id="search-body"
          class="h-full px-6 my-6"
          :on-window-keydown="select-next"
          phx-key="ArrowDown"
        >
          <div class="flex flex-col w-full sticky">
            <div class="w-full flex flex-row justify-start top-0">
              <Heroicons.Outline.SearchIcon class="h-6 w-6 mr-4 ml-4" />
              <div class="flex flex-row justify-between w-full  pb-3 border-b border-base-light-600">
                <Form for={:search} change="search" submit="go-to-doc" class="w-full">
                  <input
                    id="search-input"
                    name="search"
                    value={@search}
                    phx-debounce={300}
                    class="text-lg dark:bg-base-dark-900 grow ring-0 outline-none w-full"
                  />
                </Form>
                <button id="close-search" class="mr-4 ml-4 h-6 w-6 hover:text-base-light-400" :on-click={@close}>
                  <Heroicons.Outline.XIcon class="h-6 w-6" />
                </button>
              </div>
            </div>
            <div class="ml-2 pl-4">
              <Form for={:types} change={@change_types}>
                <div class="flex flex-row space-x-8 flex-wrap mt-4">
                  <div>Search For:</div>
                  {#for type <- AshHq.Docs.Extensions.Search.Types.types()}
                    <div class="flex flex-row items-center">
                      <Checkbox
                        class="mr-2"
                        id={"#{type}-selected"}
                        value={type in @selected_types}
                        name={"types[#{type}]"}
                      />
                      <label for={"#{type}-selected"}>
                        {type}
                      </label>
                    </div>
                  {/for}
                </div>
              </Form>
            </div>
          </div>
          <div class="grid h-[80%] mt-3">
            <div class="pl-4 overflow-auto">
              {render_items(assigns, @item_list)}
            </div>
          </div>
          <div class="flex flex-row justify-start items-center relative bottom-0 mt-2">
            <div class="flex text-black dark:text-white font-light px-2">
              Packages:
            </div>
            <AshHqWeb.Components.VersionPills
              id="search-version-pills"
              selected_versions={@selected_versions}
              remove_version={@remove_version}
              libraries={@libraries}
              toggle={toggle_libraries()}
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp render_items(assigns, items) do
    ~F"""
    {#for item <- items}
      <button
        class="block w-full text-left"
        :on-click="go-to-doc"
        phx-value-link={DocRoutes.doc_link(item, @selected_versions)}
        phx-target={@myself}
        id={item.id}
      >
        <div class={
          "rounded-lg mb-4 py-2 px-2 hover:bg-base-dark-300 dark:hover:bg-base-dark-700",
          "bg-base-light-400 dark:bg-base-dark-600": @selected_item.id == item.id,
          "bg-base-light-200 dark:bg-base-dark-800": @selected_item.id != item.id
        }>
          <div class="flex justify-start items-center space-x-2 pb-2">
            <div>
              {render_item_type(assigns, item)}
            </div>
            <div class="flex flex-row flex-wrap">
              {#for {path_item, index} <- Enum.with_index(item_path(item))}
                {#if index != 0}
                  <Heroicons.Solid.ChevronRightIcon class="h-6 w-6" />
                {/if}
                <div>
                  {path_item}
                </div>
              {/for}
              <Heroicons.Solid.ChevronRightIcon class="h-6 w-6" />
              <div class="font-bold text-lg">
                {#if item.name_matches}
                  <CalloutText text={item_name(item)} />
                {#else}
                  {item_name(item)}
                {/if}
              </div>
            </div>
          </div>
          <div class="text-base-light-700 dark:text-base-dark-400">
            {raw(item.search_headline)}
          </div>
        </div>
      </button>
    {/for}
    """
  end

  defp render_item_type(assigns, item) do
    case item_type(item) do
      "Mix Task" ->
        ~F"""
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          class="w-4 h-4"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M6.75 7.5l3 2.25-3 2.25m4.5 0h3m-9 8.25h13.5A2.25 2.25 0 0021 18V6a2.25 2.25 0 00-2.25-2.25H5.25A2.25 2.25 0 003 6v12a2.25 2.25 0 002.25 2.25z"
          />
        </svg>
        """

      "Function" ->
        case item.type do
          type when type in [:function, :macro] ->
            ~F"""
            <Heroicons.Outline.CodeIcon class="h-4 w-4" />
            """

          :callback ->
            ~F"""
            <Heroicons.Outline.AtSymbolIcon class="h-4 w-4" />
            """

          :type ->
            ~F"""
            <Heroicons.Outline.InformationCircleIcon class="h-4 w-4" />
            """
        end

      "Module" ->
        ~F"""
        <Heroicons.Outline.CodeIcon class="h-4 w-4" />
        """

      type when type in ["Dsl", "Option"] ->
        AshHqWeb.Components.DocSidebar.render_icon(assigns, item.extension_type)

      "Guide" ->
        ~F"""
        <Heroicons.Outline.BookOpenIcon class="h-4 w-4" />
        """

      _ ->
        ~F"""
        <Heroicons.Outline.PuzzleIcon class="h-4 w-4" />
        """
    end
  end

  defp toggle_libraries(js \\ %JS{}) do
    js
    |> JS.toggle(to: "#search-body")
    |> JS.toggle(to: "#search-versions")
  end

  defp item_name(%{name: name}), do: name
  defp item_name(%{version: version}), do: version

  defp item_path(%{
         library_name: library_name,
         extension_name: extension_name,
         path: path
       }) do
    [library_name, extension_name, path] |> List.flatten()
  end

  defp item_path(%{
         library_name: library_name,
         module_name: module_name
       }) do
    [library_name, module_name]
  end

  defp item_path(%{library_name: library_name}) do
    [library_name]
  end

  defp item_path(%{library_version: %{library_name: library_name}}) do
    [library_name]
  end

  defp item_path(_) do
    []
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> search()}
  end

  def handle_event("toggle_versions", _, socket) do
    {:noreply, socket |> assign(:selecting_packages, !socket.assigns.selecting_packages)}
  end

  def handle_event("search", %{"search" => search}, socket) do
    {:noreply, socket |> assign(:search, search) |> search()}
  end

  def handle_event("select-next", _, socket) do
    if socket.assigns[:selected_item] && socket.assigns[:item_list] do
      next =
        socket.assigns.item_list
        |> Enum.drop_while(&(&1.id != socket.assigns.selected_item.id))
        |> Enum.at(1)

      {:noreply, set_selected_item(socket, next)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("select-previous", _, socket) do
    if socket.assigns[:selected_item] && socket.assigns[:item_list] do
      next =
        socket.assigns.item_list
        |> Enum.reverse()
        |> Enum.drop_while(&(&1.id != socket.assigns.selected_item.id))
        |> Enum.at(1)

      {:noreply, set_selected_item(socket, next)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("go-to-doc", %{"link" => doc_link}, socket) do
    {:noreply, push_redirect(socket, to: doc_link)}
  end

  def handle_event("go-to-doc", _, socket) do
    case Enum.find(socket.assigns.item_list, fn item ->
           item.id == socket.assigns.selected_item.id
         end) do
      nil ->
        {:noreply, socket}

      item ->
        {:noreply, push_redirect(socket, to: DocRoutes.doc_link(item))}
    end
  end

  defp item_type(%resource{}) do
    AshHq.Docs.Extensions.Search.item_type(resource)
  end

  defp search(socket) do
    if socket.assigns[:search] in [nil, ""] || socket.assigns[:selected_versions] in [nil, %{}] ||
         socket.assigns[:selected_types] == [] do
      assign(socket, results: %{}, item_list: [])
    else
      versions =
        Enum.map(socket.assigns.selected_versions, fn
          {library_id, "latest"} ->
            Enum.find_value(socket.assigns.libraries, fn library ->
              if library.id == library_id do
                case AshHqWeb.Helpers.latest_version(library) do
                  nil ->
                    nil

                  version ->
                    version.id
                end
              end
            end)

          {_, version_id} ->
            version_id
        end)
        |> Enum.reject(&(&1 == "" || is_nil(&1)))

      %{result: item_list} =
        AshHq.Docs.Search.run!(
          socket.assigns.search,
          versions,
          %{types: socket.assigns[:selected_types]}
        )

      selected_item = Enum.at(item_list, 0)

      socket
      |> assign(:item_list, item_list)
      |> set_selected_item(selected_item)
    end
  end

  defp set_selected_item(socket, nil), do: socket

  defp set_selected_item(socket, selected_item) do
    socket
    |> assign(:selected_item, selected_item)
    |> push_event("js:scroll-to", %{id: selected_item.id})
  end
end
