# Flow — Master compositions

Bigger, cross-layer examples: a full Master combining Mailbox, Pool, and  
Select/Group in one coordinator.

- [Minimal Master](layer4/017-minimal_master.md)
- [Master with Pool](layer4/018-master_with_pool.md)
- [Multi-worker Master](layer4/019-multi_worker_master.md)
- [Pipeline of Masters](layer4/020-pipeline_masters.md)
- [Request-response between Masters](layer4/021-request_response.md)
- [Pool → Mailbox → Pool roundtrip](layer4/032-cross_layer_pool_mailbox_roundtrip.md)
- [Mixed types through shared mailbox](layer4/033-cross_layer_mixed_types_mailbox.md)
- [Batch receive + pool return](layer4/034-cross_layer_batch_receive_pool_return.md)
- [Pool hooks + mailbox flow](layer4/035-cross_layer_pool_hooks_mailbox_flow.md)
- [Close ordering: pool then mailbox](layer4/036-cross_layer_close_pool_then_mailbox.md)
- [Close ordering: mailbox then pool](layer4/037-cross_layer_close_mailbox_then_pool.md)
- [Pool + Mailbox flow](layer4/038-cross_layer_pool_mailbox_flow.md)
- [Master shutdown: close → stdlib walk → free](layer4/039-master_shutdown_stdlib_cleanup.md)
- [Master batch collect: receive_batch → put_all](layer4/040-master_batch_collect_receive_to_pool.md)
- [Master pre-shutdown collect](layer4/041-master_multi_mailbox_collect.md)
