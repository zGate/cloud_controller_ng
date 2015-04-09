module VCAP::CloudController
  class AppListFetcher
    def fetch(pagination_options, facets, space_guids)
      dataset = AppModel.where(space_guid: space_guids)

      if facets['names']
        dataset = dataset.where(name: facets['names'])
      end
      if facets['space_guids']
        dataset = dataset.where(space_guid: facets['space_guids'])
      end
      if facets['organization_guids']
        dataset = dataset.where(space_guid: Organization.where(guid: facets['organization_guids']).map(&:spaces).flatten.map(&:guid))
      end
      if facets['guids']
        dataset = dataset.where(guid: facets['guids'])
      end

      dataset.eager(:processes)

      SequelPaginator.new.get_page(dataset, pagination_options)
    end
  end
end
