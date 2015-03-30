require 'actions/service_binding_delete'
require 'actions/deletion_errors'

module VCAP::CloudController
  class ServiceInstanceDelete
    def delete(service_instance_dataset)
      service_instance_dataset.each_with_object([]) do |service_instance, errs|
        errors = ServiceBindingDelete.new.delete(service_instance.service_bindings_dataset)
        errs.concat(errors)
        if errors.empty?
          begin
            lock_for_delete(service_instance) do
              service_instance.client.deprovision(service_instance)
              if service_instance.managed_instance?
                service_instance.last_operation.try(:destroy)
              end
              service_instance.destroy
            end
          rescue VCAP::Errors::ApiError => e
            errs << e
          rescue HttpRequestError, HttpResponseError => e
            errs << e
          ensure
            service_instance.save_with_operation(
              last_operation: {
                type: 'delete',
                state: 'failed',
              }
            ) if service_instance.exists?
          end
        end
      end
    end

    def lock_for_delete(service_instance, &block)
      if service_instance.managed_instance?
        service_instance.lock_by_failing_other_operations('delete', &block)
      else
        block.call
      end
    end
  end
end
